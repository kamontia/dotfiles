local M = {}

local function compact_merge_layout(view)
  local layout = view and view.cur_layout

  if not (layout and layout.a and layout.b and layout.c) then
    return
  end

  local top_lines = math.max(
    vim.api.nvim_buf_line_count(layout.a.file.bufnr),
    vim.api.nvim_buf_line_count(layout.c.file.bufnr)
  )
  local top_height = math.max(4, math.min(top_lines + 2, 8))

  pcall(vim.api.nvim_win_set_height, layout.a.id, top_height)
  pcall(vim.api.nvim_win_set_height, layout.c.id, top_height)
end

local function patch_merge_winbar_labels()
  local FileEntry = require("diffview.scene.file_entry").FileEntry

  if FileEntry._edmond_merge_winbar_patched then
    return
  end

  FileEntry._edmond_merge_winbar_patched = true

  local original = FileEntry.update_merge_context

  function FileEntry:update_merge_context(ctx)
    original(self, ctx)

    local layout = self.layout

    if layout.a and layout.a.file then
      layout.a.file.winbar = " LOCAL"
    end

    if layout.b and layout.b.file then
      layout.b.file.winbar = " FINAL"
    end

    if layout.c and layout.c.file then
      layout.c.file.winbar = " REMOTE"
    end
  end
end

local function open_when_ready(path, retries)
  local actions = require("diffview.actions")
  local lib = require("diffview.lib")
  local view = lib.get_current_view()

  if view and view.set_file_by_path then
    view:set_file_by_path(path, true, true)

    vim.defer_fn(function()
      actions.toggle_files()
      vim.defer_fn(function()
        compact_merge_layout(view)
      end, 50)
    end, 50)
    return
  end

  if retries <= 0 then
    vim.notify("Diffview の競合ビューを開けませんでした", vim.log.levels.ERROR)
    return
  end

  vim.defer_fn(function()
    open_when_ready(path, retries - 1)
  end, 50)
end

function M.open_current_conflict()
  local path = vim.fn.expand("%:.")

  if path == "" then
    vim.notify("競合ファイルを開いてから実行してください", vim.log.levels.WARN)
    return
  end

  vim.cmd("DiffviewOpen")
  open_when_ready(path, 20)
end

local function get_main_context()
  local lib = require("diffview.lib")
  local StandardView = require("diffview.scene.views.standard.standard_view").StandardView
  local view = lib.get_current_view()

  if not (view and view:instanceof(StandardView)) then
    return
  end

  local main = view.cur_layout:get_main_win()
  local curfile = main.file

  if not (main:is_valid() and curfile:is_valid()) then
    return
  end

  return view, main, curfile
end

local function local_remote_content(conflict)
  local utils = require("diffview.utils")

  return utils.vec_join(conflict.ours.content, conflict.theirs.content)
end

function M.choose_local_remote()
  local _, main, curfile = get_main_context()

  if not main then
    return
  end

  local vcs_utils = require("diffview.vcs.utils")
  local utils = require("diffview.utils")
  local _, cur = vcs_utils.parse_conflicts(
    vim.api.nvim_buf_get_lines(curfile.bufnr, 0, -1, false),
    main.id
  )

  if not cur then
    return
  end

  local content = local_remote_content(cur)
  vim.api.nvim_buf_set_lines(curfile.bufnr, cur.first - 1, cur.last, false, content)
  utils.set_cursor(main.id, unpack({
    #content + cur.first - 1,
    content[1] and #content[#content] or 0,
  }))
end

function M.choose_all_local_remote()
  local _, main, curfile = get_main_context()

  if not main then
    return
  end

  local vcs_utils = require("diffview.vcs.utils")
  local lines = vim.api.nvim_buf_get_lines(curfile.bufnr, 0, -1, false)
  local conflicts = vcs_utils.parse_conflicts(lines, main.id)

  if not next(conflicts) then
    return
  end

  local offset = 0

  for _, conflict in ipairs(conflicts) do
    local first = conflict.first + offset
    local last = conflict.last + offset
    local content = local_remote_content(conflict)

    vim.api.nvim_buf_set_lines(curfile.bufnr, first - 1, last, false, content)
    offset = offset + (#content - (last - first) - 1)
  end
end

function M.setup()
  patch_merge_winbar_labels()
end

return M
