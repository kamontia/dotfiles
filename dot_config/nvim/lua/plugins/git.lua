return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- ハンク間の移動
        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next hunk")
        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev hunk")

        -- ハンク操作
        map("n", "<leader>gs", gs.stage_hunk,   "Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk,   "Reset hunk")
        map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")

        -- 差分プレビュー
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")

        -- blame
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")

        -- diffview との連携
        map("n", "<leader>gd", gs.diffthis, "Diff this")

        -- ビジュアルモードでのハンク操作
        map("v", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage hunk (visual)")
        map("v", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset hunk (visual)")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gD", "<cmd>DiffviewOpen<cr>",            desc = "Diffview: open" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>",   desc = "Diffview: file history" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>",     desc = "Diffview: repo history" },
      { "<leader>gx", "<cmd>DiffviewClose<cr>",           desc = "Diffview: close" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
      },
    },
  },
  {
    "FabijanZulj/blame.nvim",
    keys = {
      { "<leader>gl", "<cmd>BlameToggle<cr>", desc = "Blame: toggle" },
    },
    opts = {
      date_format = "%Y/%m/%d",
      focus_blame = true,
      merge_consecutive = false,
      commit_detail_view = "vsplit",
    },
  },
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
    },
  },
}
