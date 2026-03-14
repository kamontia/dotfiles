-- Neovim options
local opt = vim.opt

-- Encoding settings for Japanese
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileencodings = "utf-8,ucs-bom,sjis,euc-jp,latin1"

opt.number = true
opt.relativenumber = true
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"
opt.updatetime = 250
opt.timeoutlen = 300

-- nvim-ufo (fold)
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
