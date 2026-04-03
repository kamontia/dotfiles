return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "center",
        layout_config = {
          center = {
            width = 0.8,
            height = 0.6,
            preview_cutoff = 40,
            prompt_position = "top",
          },
        },
        sorting_strategy = "ascending",
        border = true,
      },
    },
  },
}
