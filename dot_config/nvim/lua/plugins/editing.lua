return {
  -- 高速カーソル移動
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,             desc = "Flash Remote" },
      { "R", mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
    },
  },
  -- テキストオブジェクト拡張
  {
    "nvim-mini/mini.ai",
    version = false,
    event = "VeryLazy",
    opts = {
      n_lines = 500,
    },
  },
  -- undo 履歴のツリー表示
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
    },
  },
  -- fold の強化
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    opts = {
      open_fold_hl_timeout = 400,
      close_fold_kinds_for_ft = {
        default = { "imports", "comment" },
      },
    },
    config = function(_, opts)
      require("ufo").setup(opts)
      vim.keymap.set("n", "zR", require("ufo").openAllFolds,       { desc = "Open all folds" })
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds,      { desc = "Close all folds" })
      vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds, { desc = "Open folds except kinds" })
      vim.keymap.set("n", "zm", require("ufo").closeFoldsWith,     { desc = "Close folds with" })
    end,
  },
  -- セッション自動保存
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      need = 1,
      branch = true,
    },
    keys = {
      { "<leader>qs", function() require("persistence").load() end,              desc = "Restore session" },
      { "<leader>qS", function() require("persistence").select() end,            desc = "Select session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Load last session" },
      { "<leader>qd", function() require("persistence").stop() end,              desc = "Stop session saving" },
    },
  },
}
