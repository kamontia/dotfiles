-- Neovim keymaps
local keymap = vim.keymap

-- Telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")

-- Window navigation
keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-k>", "<C-w>k")
keymap.set("n", "<C-l>", "<C-w>l")

-- Clear search with ESC
keymap.set("n", "<Esc>", "<cmd>noh<CR>")

-- jk to escape
keymap.set("i", "jk", "<Esc>")

-- Yazi
keymap.set("n", "<leader>e", "<cmd>Yazi<cr>", { desc = "Open Yazi" })

-- Zoxide
keymap.set("n", "<leader>fz", "<cmd>Telescope zoxide list<cr>", { desc = "Zoxide directories" })

-- TODO comments
keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "TODO list" })

-- gitui
keymap.set("n", "<leader>gg", "<cmd>Gitui<cr>", { desc = "Open gitui" })

-- Format
keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })

-- Trouble
keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle Trouble" })

-- Diagnostics navigation
keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
