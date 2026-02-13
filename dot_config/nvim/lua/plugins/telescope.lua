return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "jvgrootveld/telescope-zoxide",
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      extensions = {
        fzf = {},
      },
    })
    telescope.load_extension("fzf")
    telescope.load_extension("zoxide")
  end,
}
