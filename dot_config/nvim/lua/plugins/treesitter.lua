return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  opts = {
    ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "go" },
    highlight = { enable = true },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
      },
    },
  },
}
