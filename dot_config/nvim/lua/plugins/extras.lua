return {
  -- カーソル行に blame を常時表示
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,           -- 表示までの遅延（ms）
        virt_text_pos = "eol", -- 行末に表示
      },
    },
  },

  -- ミニマップ（右端にバッファ全体の俯瞰 + gitsigns / diagnostics 連携）
  {
    "nvim-mini/mini.map",
    event = "VeryLazy",
    keys = {
      { "<leader>uM", function() require("mini.map").toggle() end,            desc = "Minimap toggle" },
      { "<leader>u<leader>M", function() require("mini.map").toggle_side() end, desc = "Minimap toggle side" },
    },
    config = function()
      local map = require("mini.map")
      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),   -- 検索ハイライト
          map.gen_integration.diagnostic(),        -- LSP diagnostics
          map.gen_integration.gitsigns(),          -- git diff hunks
        },
        symbols = {
          encode = map.gen_encode_symbols.dot("4x2"), -- ドット文字でエンコード
          scroll_line = "█",
          scroll_view = "┃",
        },
        window = {
          side        = "right", -- 右端に表示
          width       = 10,      -- 横幅（文字数）
          winblend    = 15,      -- 半透明度（0=不透明, 100=完全透明）
          show_integration_count = false,
        },
      })
    end,
  },

  -- Python venv 選択 (Telescope UI)
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    ft = "python",
    opts = {},
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },
    },
  },

  -- mise ランタイム管理との連携
  {
    "https://plugins.ejri.dev/mise.nvim",
    opts = {},
  },

  -- Git 操作補助
  {
    "tpope/vim-fugitive",
    cmd = {
      "Git",
      "G",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Gread",
      "Gwrite",
    },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>",           desc = "Git summary" },
      { "<leader>gM", "<cmd>Git mergetool<cr>", desc = "Git merge quickfix" },
    },
  },

  -- Git コンフリクト解消マーカー補助
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    opts = {},
  },

  -- tmux との統合ナビゲーション (Ctrl+hjkl)
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft", "TmuxNavigateDown",
      "TmuxNavigateUp", "TmuxNavigateRight",
    },
    init = function()
      -- プラグイン側の VimL キーマップ自動登録を無効化（lua 側で完全制御するため）
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      -- zen_mode_active フラグが立っている間はペイン移動しない
      { "<C-h>", function() if not vim.g.zen_mode_active then vim.cmd("TmuxNavigateLeft")  end end, desc = "Move to left pane" },
      { "<C-j>", function() if not vim.g.zen_mode_active then vim.cmd("TmuxNavigateDown")  end end, desc = "Move to lower pane" },
      { "<C-k>", function() if not vim.g.zen_mode_active then vim.cmd("TmuxNavigateUp")    end end, desc = "Move to upper pane" },
      { "<C-l>", function() if not vim.g.zen_mode_active then vim.cmd("TmuxNavigateRight") end end, desc = "Move to right pane" },
    },
  },

  -- ファイルエクスプローラー（fuzzy finder 内 Ctrl+n/p でジャンプ）
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      -- snacks_explorer に <leader>e/E/fe/fE を委ねるため neo-tree extra のデフォルトを無効化
      { "<leader>e",  false },
      { "<leader>E",  false },
      { "<leader>fe", false },
      { "<leader>fE", false },
      -- NeoTree 専用バインド（snacks とは別に必要なときに起動）
      { "<leader>N",  "<cmd>Neotree toggle<cr>",                                          desc = "NeoTree toggle (root dir)" },
      { "<leader>Ng", function() require("neo-tree.command").execute({ source = "git_status", toggle = true }) end, desc = "NeoTree git status" },
      { "<leader>Nb", function() require("neo-tree.command").execute({ source = "buffers",    toggle = true }) end, desc = "NeoTree buffers" },
    },
    opts = {
      filesystem = {
        fuzzy_finder_mappings = {
          ["<C-n>"] = "move_cursor_down",
          ["<C-p>"] = "move_cursor_up",
        },
      },
    },
  },

  -- Git diff / 履歴ビューア
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",        desc = "Diff view open" },
      { "<leader>gm", function() require("config.diffview_merge").open_current_conflict() end, desc = "Current conflict view" },
      { "<leader>gu", function() require("config.diffview_unsaved").prompt_open() end, desc = "Unsaved diff prompt" },
      { "<leader>gU", function() require("config.diffview_unsaved").open_default() end, desc = "Unsaved diff open" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File history" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>",       desc = "Diff view close" },
    },
    opts = {
      view = {
        -- マージコンフリクト時の 3 ペイン表示
        -- diff3_mixed : 上段に ours/theirs を横並び、下段に結果（推奨）
        -- diff3_horizontal : 3 ペインを縦に積む
        -- diff3_vertical   : 3 ペインを横に並べる
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
          winbar_info = true,
        },
      },
      keymaps = {
        view = {
          -- view（差分バッファ）では gd を LSP 定義ジャンプに戻す（デフォルト上書きを削除）
          -- gf はデフォルト済み（goto_file_edit）のままファイルを開く用途に使用
          -- snacks_explorer と競合する diffview 内部の <leader>e を無効化
          { "n", "<leader>e", false },
          { "n", "<leader>cm", function() require("config.diffview_merge").choose_local_remote() end, { desc = "Choose local + remote" } },
          { "n", "<leader>cM", function() require("config.diffview_merge").choose_all_local_remote() end, { desc = "Choose local + remote for file" } },
        },
        file_panel = {
          -- ファイルパネルでは gd / gf でファイルを開く
          { "n", "gd", function() require("diffview.actions").goto_file_edit() end, { desc = "ファイルを開く (edit)" } },
          { "n", "<leader>e", false },
          { "n", "<leader>cM", function() require("config.diffview_merge").choose_all_local_remote() end, { desc = "Choose local + remote for file" } },
        },
        file_history_panel = {
          { "n", "gd", function() require("diffview.actions").goto_file_edit() end, { desc = "ファイルを開く (edit)" } },
          { "n", "<leader>e", false },
        },
      },
      hooks = {
        -- diffview で開いたバッファを編集可能にする
        diff_buf_read = function(bufnr)
          vim.bo[bufnr].modifiable = true
        end,
      },
    },
    config = function(_, opts)
      require("diffview").setup(opts)
      require("config.diffview_merge").setup()
    end,
  },

  -- 括弧・クォートの操作 (ys / cs / ds)
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- TODO / FIXME などのハイライトと検索
  {
    "folke/todo-comments.nvim",
    -- LazyVim が既に読み込むので opts のみ上書き
    opts = {
      signs = true,
    },
  },

  -- DAP UI (nvim-dap は lazyvim extras.dap.core で追加済み)
  {
    "rcarriga/nvim-dap-ui",
    -- LazyVim extras.dap.core に含まれるため opts のみ調整
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes",      size = 0.33 },
            { id = "breakpoints", size = 0.17 },
            { id = "stacks",      size = 0.25 },
            { id = "watches",     size = 0.25 },
          },
          size = 0.30,
          position = "left",
        },
        {
          elements = {
            { id = "repl",    size = 0.45 },
            { id = "console", size = 0.55 },
          },
          size = 0.27,
          position = "bottom",
        },
      },
    },
  },

  -- Claude / GPT をneovim内から使う
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      strategies = {
        chat = { adapter = "anthropic" },
        inline = { adapter = "anthropic" },
      },
    },
    keys = {
      { "<leader>ac", "<cmd>CodeCompanionChat<cr>",   desc = "CodeCompanion Chat" },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions" },
    },
    cmd = { "CodeCompanionChat", "CodeCompanionActions", "CodeCompanion" },
  },

  -- コマンドライン・通知をポップアップ化
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
      },
    },
  },

  -- 集中モード（余白を消してフォーカス）
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = { width = 0.85 },
      on_open = function()
        vim.g.zen_mode_active = true
      end,
      on_close = function()
        vim.g.zen_mode_active = false
      end,
    },
  },

  -- lazygit / ファイルパスコピー (snacks.nvim 経由で有効化)
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts = opts or {}

      local search_open = require("config.snacks_explorer_search_open")
      local explorer = vim.tbl_deep_extend(
        "force",
        {},
        opts.picker and opts.picker.sources and opts.picker.sources.explorer or {},
        search_open.explorer_opts()
      )

      opts.lazygit = opts.lazygit or { enabled = true }
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = explorer
    end,
    keys = {
      {
        "<leader>fy",
        function()
          local path = vim.fn.expand("%:p")
          vim.fn.setreg("+", path)
          vim.notify("Copied: " .. path)
        end,
        desc = "Copy absolute path",
      },
      {
        "<leader>fY",
        function()
          local path = vim.fn.expand("%")
          vim.fn.setreg("+", path)
          vim.notify("Copied: " .. path)
        end,
        desc = "Copy relative path",
      },
    },
  },

  -- vim.ui.input / select をリッチUIに
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- ブラウザで Markdown をリアルタイムプレビュー
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = "markdown",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview (browser)" },
      {
        "<leader>mP",
        function()
          local theme = vim.g.mkdp_theme == "dark" and "light" or "dark"
          vim.g.mkdp_theme = theme
          vim.notify("Markdown Preview theme: " .. theme, vim.log.levels.INFO)
        end,
        desc = "Markdown Preview theme toggle",
      },
    },
    init = function()
      vim.g.mkdp_theme = "light"
    end,
  },
}
