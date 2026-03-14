return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true, -- VSCodeのように1本のステータスバー
      },
      sections = {
        lualine_c = {
          { "filename", path = 3 }, -- プロジェクトルート(LSP/Git root)からの相対パス
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        separator_style = "slant",      -- VSCodeライクな斜めタブ
        show_buffer_close_icons = true,
        show_close_icon = false,
        color_icons = true,
        diagnostics = "nvim_lsp",       -- LSP診断をタブに表示
        diagnostics_indicator = function(_, _, diag)
          local icons = { error = " ", warning = " " }
          local ret = (diag.error and icons.error .. diag.error .. " " or "")
            .. (diag.warning and icons.warning .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            text_align = "center",
            separator = true,           -- neo-treeとの境界線
          },
        },
      },
    },
  },
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
}
