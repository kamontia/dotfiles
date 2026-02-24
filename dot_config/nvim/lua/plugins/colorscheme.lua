return {
  -- VSCode風テーマ候補（どちらかをコメントアウトして切り替え）
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    enabled = false, -- tokyonightを使う場合はfalse、切り替えはこのフラグとconfig側を変更
    config = function()
      vim.cmd.colorscheme("onedark")
    end,
  },
  -- 元のcatppuccin（必要なら戻せるよう残す）
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    enabled = false,
    config = function()
      vim.cmd.colorscheme("catppuccin-macchiato")
    end,
  },
}
