-- Neovim init.lua

-- Set locale environment variables
vim.env.LANG = "ja_JP.UTF-8"
vim.env.LC_ALL = "ja_JP.UTF-8"

-- Force UTF-8 for Git messages
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "COMMIT_EDITMSG", "git-rebase-todo", "MERGE_MSG" },
  callback = function()
    vim.opt_local.fileencoding = "utf-8"
  end,
})

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Base settings
require("config.options")
require("config.keymaps")

-- Setup plugins
require("lazy").setup("plugins")
