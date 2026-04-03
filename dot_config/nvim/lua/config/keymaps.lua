-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- jk で Insert/Visual モードから Normal モードへ
vim.keymap.set("i", "jk", "<Esc>", { desc = "Normal mode" })
vim.keymap.set("v", "jk", "<Esc>", { desc = "Normal mode" })

-- diffview 使用中でもプロジェクトルートから操作できるようにする
-- LazyVim のデフォルトキーを上書きして常に root dir を使う
vim.keymap.set("n", "<leader>/", function()
  require("telescope.builtin").live_grep({ cwd = LazyVim.root() })
end, { desc = "Grep (root dir)" })

vim.keymap.set("n", "<leader><space>", function()
  require("telescope.builtin").find_files({ cwd = LazyVim.root() })
end, { desc = "Find Files (root dir)" })

vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ cwd = LazyVim.root() })
end, { desc = "Find Files (root dir)" })
