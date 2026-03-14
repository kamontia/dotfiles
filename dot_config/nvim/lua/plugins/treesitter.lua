return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      -- highlight
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
      -- textobjects（新API）
      require("nvim-treesitter-textobjects").setup({})
      local move = require("nvim-treesitter-textobjects.move")
      local select = require("nvim-treesitter-textobjects.select")
      -- select
      local keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      }
      for key, capture in pairs(keymaps) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(capture, "textobjects")
        end, { desc = "Select " .. capture })
      end
      -- move
      vim.keymap.set("n", "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
      vim.keymap.set("n", "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function" })
      vim.keymap.set("n", "]C", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
      vim.keymap.set("n", "[C", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class" })
    end,
  },
}
