local uv = vim.uv or vim.loop

local CDiffView = require("diffview.api.views.diff.diff_view").CDiffView
local arg_parser = require("diffview.arg_parser")
local lib = require("diffview.lib")
local vcs = require("diffview.vcs")

local M = {}

local DEFAULT_RANGE = "origin/HEAD...HEAD"
local POLL_INTERVAL_MS = 300
local view_timers = setmetatable({}, { __mode = "k" })
local tracked_cache = {}

local function normalize_path(path)
  return vim.fs.normalize(path)
end

local function repo_relpath(toplevel, path)
  local root = normalize_path(toplevel)
  local abs = normalize_path(path)
  local prefix = root .. "/"

  if abs == root then
    return "."
  end

  if abs:sub(1, #prefix) ~= prefix then
    return nil
  end

  return abs:sub(#prefix + 1)
end

local function build_pathspec_args(path_args)
  if not path_args or vim.tbl_isempty(path_args) then
    return {}
  end

  return vim.list_extend({ "--" }, vim.deepcopy(path_args))
end

local function exec_git(adapter, args, opt)
  local stdout, code, stderr = adapter:exec_sync(args, vim.tbl_extend("force", {
    cwd = adapter.ctx.toplevel,
    silent = true,
  }, opt or {}))

  return stdout or {}, code or 1, stderr or {}
end

local function parse_name_and_oldname(line)
  local name = line:match("[%a%s][^%s]*\t(.*)")
  if not name then
    return nil, nil
  end

  local oldname
  if name:match("\t") then
    oldname = name:match("(.*)\t")
    name = name:gsub("^.*\t", "")
  end

  return name, oldname
end

local function parse_diff_file_data(adapter, left, right, path_args)
  local rev_args = adapter:rev_to_args(left, right)
  local pathspec_args = build_pathspec_args(path_args)
  local diff_args = vim.list_extend(rev_args, pathspec_args)

  local name_status_cmd = vim.list_extend({
    "-c",
    "core.quotePath=false",
    "diff",
    "--ignore-submodules",
    "--name-status",
  }, vim.deepcopy(diff_args))

  local numstat_cmd = vim.list_extend({
    "-c",
    "core.quotePath=false",
    "diff",
    "--ignore-submodules",
    "--numstat",
  }, vim.deepcopy(diff_args))

  local name_status_out, name_status_code, name_status_err = exec_git(adapter, name_status_cmd)
  if name_status_code ~= 0 then
    error(table.concat(name_status_err, "\n"))
  end

  local numstat_out, numstat_code, numstat_err = exec_git(adapter, numstat_cmd)
  if numstat_code ~= 0 then
    error(table.concat(numstat_err, "\n"))
  end

  local working = {}
  local conflicting = {}

  for i, line in ipairs(name_status_out) do
    local status = line:sub(1, 1):gsub("%s", " ")
    local name, oldname = parse_name_and_oldname(line)

    if name then
      local stats_line = numstat_out[i] or ""
      local stats = {
        additions = tonumber(stats_line:match("^(%d+)")),
        deletions = tonumber(stats_line:match("^%d+%s+(%d+)")),
      }

      if not stats.additions or not stats.deletions then
        stats = nil
      end

      local entry = {
        path = name,
        oldpath = oldname,
        status = status,
        stats = stats,
      }

      if left.type == 1 and right.type ~= 1 and entry.stats then
        entry.stats.additions, entry.stats.deletions = entry.stats.deletions, entry.stats.additions
      end

      if status == "U" then
        conflicting[#conflicting + 1] = entry
      else
        working[#working + 1] = entry
      end
    end
  end

  return working, conflicting
end

local function list_untracked_files(adapter, path_args)
  local cmd = vim.list_extend({
    "-c",
    "core.quotePath=false",
    "ls-files",
    "--others",
    "--exclude-standard",
  }, build_pathspec_args(path_args))

  local stdout, code, stderr = exec_git(adapter, cmd)
  if code ~= 0 then
    error(table.concat(stderr, "\n"))
  end

  local files = {}
  for _, path in ipairs(stdout) do
    files[#files + 1] = {
      path = path,
      status = "?",
    }
  end

  return files
end

local function modified_repo_buffers(toplevel)
  local buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" and vim.bo[bufnr].modified then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        local relpath = repo_relpath(toplevel, name)
        if relpath then
          buffers[relpath] = bufnr
        end
      end
    end
  end

  return buffers
end

local function is_tracked(adapter, path)
  if tracked_cache[path] ~= nil then
    return tracked_cache[path]
  end

  local _, code = exec_git(adapter, { "ls-files", "--error-unmatch", "--", path })
  local tracked = code == 0
  tracked_cache[path] = tracked

  return tracked
end

local function sort_files(files)
  table.sort(files, function(a, b)
    return a.path:lower() < b.path:lower()
  end)
end

local function build_custom_file_data(view)
  local adapter = view.adapter
  local working, conflicting = parse_diff_file_data(adapter, view.left, view.right, view.path_args)
  local known_paths = {}

  for _, file in ipairs(working) do
    known_paths[file.path] = true
    if view.options.selected_file == file.path then
      file.selected = true
    end
  end

  for _, file in ipairs(conflicting) do
    known_paths[file.path] = true
    if view.options.selected_file == file.path then
      file.selected = true
    end
  end

  if view.options.show_untracked then
    for _, file in ipairs(list_untracked_files(adapter, view.path_args)) do
      known_paths[file.path] = true
      if view.options.selected_file == file.path then
        file.selected = true
      end
      working[#working + 1] = file
    end
  end

  for path in pairs(modified_repo_buffers(adapter.ctx.toplevel)) do
    if not known_paths[path] then
      working[#working + 1] = {
        path = path,
        status = is_tracked(adapter, path) and "M" or "?",
        selected = view.options.selected_file == path,
      }
      known_paths[path] = true
    end
  end

  sort_files(working)
  sort_files(conflicting)

  return {
    working = working,
    staged = {},
    conflicting = conflicting,
  }
end

local function stop_polling(view)
  local timer = view_timers[view]
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  view_timers[view] = nil
end

local function current_unsaved_signature(toplevel)
  local parts = {}

  for relpath, bufnr in pairs(modified_repo_buffers(toplevel)) do
    parts[#parts + 1] = string.format("%s:%s", relpath, vim.api.nvim_buf_get_changedtick(bufnr))
  end

  table.sort(parts)
  return table.concat(parts, "|")
end

local function start_polling(view)
  stop_polling(view)

  local timer = assert(uv.new_timer())
  local last_signature = current_unsaved_signature(view.adapter.ctx.toplevel)
  view_timers[view] = timer

  timer:start(POLL_INTERVAL_MS, POLL_INTERVAL_MS, vim.schedule_wrap(function()
    if view.closing:check() or not view.tabpage or not vim.api.nvim_tabpage_is_valid(view.tabpage) then
      stop_polling(view)
      return
    end

    if view.tabpage ~= vim.api.nvim_get_current_tabpage() or not view.ready then
      return
    end

    local signature = current_unsaved_signature(view.adapter.ctx.toplevel)
    if signature ~= last_signature then
      last_signature = signature
      view:update_files()
    end
  end))
end

local function open_custom_diffview(range)
  local target = vim.trim(range or "")
  if target == "" then
    target = DEFAULT_RANGE
  end

  local err, adapter = vcs.get_adapter({
    cmd_ctx = {
      path_args = {},
      cpath = nil,
    },
  })

  if err then
    vim.notify(err, vim.log.levels.ERROR, { title = "Diffview" })
    return
  end

  local argo = arg_parser.parse({ target, "--imply-local", "-u" })
  local opts = adapter:diffview_options(argo)
  if not opts then
    return
  end

  local view = CDiffView({
    git_root = adapter.ctx.toplevel,
    rev_arg = target,
    path_args = adapter.ctx.path_args,
    left = opts.left,
    right = opts.right,
    options = opts.options,
    update_files = build_custom_file_data,
  })

  if not view:is_valid() then
    return
  end

  lib.add_view(view)
  view:open()
  start_polling(view)
  view.emitter:on("view_closed", function()
    stop_polling(view)
  end)
end

function M.prompt_open()
  vim.ui.input({
    prompt = "Diff base range: ",
    default = DEFAULT_RANGE,
  }, function(input)
    if input == nil then
      return
    end

    open_custom_diffview(input)
  end)
end

function M.open_default()
  open_custom_diffview(DEFAULT_RANGE)
end

return M
