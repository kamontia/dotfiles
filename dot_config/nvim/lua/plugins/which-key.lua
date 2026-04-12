return {
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix",
      win = {
        row = math.huge,  -- 画面最下部
        col = 0,          -- 左端から開始
        width = 1000,     -- 画面幅いっぱい（実際の幅にクランプされる）
        border = "single",
        padding = { 1, 2 },
      },
      layout = {
        width = { min = 20 },
        spacing = 4,
      },
    },
  },
}
