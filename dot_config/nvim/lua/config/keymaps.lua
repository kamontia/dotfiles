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

-- Neo-tree（Cmd+B でVSCodeライクにトグル、Cmd+B+Shift でフォーカス移動）
keymap.set("n", "<D-b>", "<cmd>Neotree toggle<cr>", { desc = "Toggle Neo-tree" })
keymap.set("n", "\x1b[98;9u", "<cmd>Neotree toggle<cr>", { desc = "Toggle Neo-tree (Cmd+B)" })
keymap.set("n", "<M-b>", "<cmd>Neotree toggle<cr>", { desc = "Toggle Neo-tree (tmux Cmd+B)" })
keymap.set("n", "<leader>o", "<cmd>Neotree focus<cr>", { desc = "Focus Neo-tree" })
keymap.set("n", "<D-B>", "<cmd>Neotree focus<cr>", { desc = "Focus Neo-tree (Cmd+Shift+B)" })
keymap.set("n", "\x1b[66;9u", "<cmd>Neotree focus<cr>", { desc = "Focus Neo-tree (Cmd+Shift+B csi)" })
keymap.set("n", "<M-B>", "<cmd>Neotree focus<cr>", { desc = "Focus Neo-tree (tmux Cmd+Shift+B)" })

-- Zoxide
keymap.set("n", "<leader>fz", "<cmd>Telescope zoxide list<cr>", { desc = "Zoxide directories" })

-- TODO comments
keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "TODO list" })

-- lazygit（git.lua の keys で定義済み）

-- ターミナル
keymap.set("n", "<leader>th", "<cmd>split | terminal<cr>", { desc = "Terminal (horizontal)" })
keymap.set("n", "<leader>tv", "<cmd>vsplit | terminal<cr>", { desc = "Terminal (vertical)" })
keymap.set("t", "<Esc>", function()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name:find("lazygit") then
    return "<Esc>"
  end
  return "<C-\\><C-n>"
end, { expr = true, desc = "Exit terminal mode (passthrough in lazygit)" })

-- Format
keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

-- Bufferline
keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

-- Trouble
keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle Trouble" })

-- Diagnostics navigation
keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

