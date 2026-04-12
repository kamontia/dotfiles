-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- harpoonバッファでtreesitterを無効化（mini.aiのエラー回避）
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("harpoon_no_treesitter", { clear = true }),
  pattern = "harpoon",
  callback = function()
    vim.treesitter.stop()
  end,
})

-- neo-tree: 展開・折畳ショートカット
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("neotree_keymaps", { clear = true }),
  pattern = "neo-tree",
  callback = function(event)
    local map = function(key, fn, desc)
      vim.keymap.set("n", key, fn, { buffer = event.buf, noremap = true, nowait = true, silent = true, desc = desc })
    end
    map("W", function()
      local state = require("neo-tree.sources.manager").get_state("filesystem")
      require("neo-tree.sources.filesystem.commands").expand_all_nodes(state)
    end, "Expand all nodes")
    map("gW", function()
      local state = require("neo-tree.sources.manager").get_state("filesystem")
      require("neo-tree.sources.filesystem.commands").expand_all_subnodes(state)
    end, "Expand subnodes")
    map("gC", function()
      local state = require("neo-tree.sources.manager").get_state("filesystem")
      require("neo-tree.sources.common.commands").close_all_subnodes(state)
    end, "Close subnodes")
  end,
})

-- nvim設定ファイルを保存したら自動で再読み込み
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("reload_config", { clear = true }),
  pattern = vim.fn.stdpath("config") .. "/lua/**/*.lua",
  callback = function(event)
    local src = event.match
    -- lazy.lua は再読み込み不可のためスキップ
    if src:find("lazy%.lua$") then return end
    dofile(src)
    vim.notify("Config reloaded: " .. vim.fn.fnamemodify(src, ":~"), vim.log.levels.INFO)
  end,
})
