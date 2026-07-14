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
          -- 左ペインの revision バッファからも実ファイル基準で LSP ジャンプできるようにする
          { "n", "gd", function() require("config.diffview_lsp").goto_definition() end, { desc = "Goto definition" } },
          { "n", "gf", function() require("config.diffview_lsp").goto_file_edit() end, { desc = "Open file (edit)" } },
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

      -- 通常 diff (diff2_horizontal) の左右を逆にする
      -- 標準: 左=旧リビジョン(a) / 右=作業ツリー(b)
      -- 変更: 左=作業ツリー(b) / 右=旧リビジョン(a)
      -- ※ プラグイン本体を書き換えず create メソッドのみ上書き（更新で消えない）
      local async = require("diffview.async")
      local Window = require("diffview.scene.window").Window
      local Diff2Hor = require("diffview.scene.layouts.diff_2_hor").Diff2Hor
      local api = vim.api
      local await = async.await

      Diff2Hor.create = async.void(function(self, pivot)
        self:create_pre()
        local curwin

        pivot = pivot or self:find_pivot()
        assert(api.nvim_win_is_valid(pivot), "Layout creation requires a valid window pivot!")

        for _, win in ipairs(self.windows) do
          if win.id ~= pivot then
            win:close(true)
          end
        end

        -- レイアウト目的: DiffviewFileHistory(コミット間比較) で
        --   ファイルパネル(左端) | 真ん中=新しいコミット | 右=古いコミット
        -- にする。
        --
        -- diffview の Diff2 では a=左リビジョン(履歴では古い側) / b=右リビジョン(履歴では新しい側)。
        -- 実測(:DiagE382 で wincol を確認)では、aboveleft vsp を 2 回行うと
        --   「先に生成したウィンドウが真ん中(col 小) / 後に生成したウィンドウが右(col 大)」
        -- になる。
        -- よって真ん中に新しい b を出すには b を先・a を後に生成する。
        --
        -- 注意: この diff は両ペインとも git 履歴(buftype=nowrite)で読み取り専用。
        -- 編集して :w すると E382: Cannot write, 'buftype' option is set が出るのは仕様
        -- (作業ツリーを含まないコミット間比較のため、そもそも編集対象が無い)。
        api.nvim_win_call(pivot, function()
          vim.cmd("aboveleft vsp")
          curwin = api.nvim_get_current_win()

          if self.b then
            self.b:set_id(curwin)
          else
            self.b = Window({ id = curwin })
          end
        end)

        api.nvim_win_call(pivot, function()
          vim.cmd("aboveleft vsp")
          curwin = api.nvim_get_current_win()

          if self.a then
            self.a:set_id(curwin)
          else
            self.a = Window({ id = curwin })
          end
        end)

        api.nvim_win_close(pivot, true)
        self.windows = { self.a, self.b }
        await(self:create_post())
      end)
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

      opts.lazygit = vim.tbl_deep_extend("force", {
        enabled = true,
        config = {
          os = {
            -- nvim-remote は commit メッセージ等の単発編集は動くが、
            -- interactive rebase (Ctrl+g の複数コミット編集) では
            -- git-rebase-todo を --remote-tab で開いた結果バッファの buftype が
            -- 設定された状態になり :w 時に E382 で保存できない。
            -- lazygit ターミナル内で新しい nvim を起動する "nvim" なら
            -- エディタの終了待ちが正しく機能し buftype も空のまま保存できる。
            editPreset = "nvim",
          },
        },
      }, opts.lazygit or {})
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
    init = function()
      vim.g.mkdp_theme = "light"
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/styles/markdown-preview.css"

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("markdown_preview_keymaps", { clear = true }),
        pattern = "markdown",
        callback = function(event)
          local map = function(key, fn, desc)
            vim.keymap.set("n", key, fn, { buffer = event.buf, noremap = true, silent = true, desc = desc })
          end

          map("<leader>mp", function()
            require("lazy").load({ plugins = { "markdown-preview.nvim" } })
            vim.fn["mkdp#util#toggle_preview"]()
          end, "Markdown Preview (browser)")

          map("<leader>mP", function()
            local theme = vim.g.mkdp_theme == "dark" and "light" or "dark"
            vim.g.mkdp_theme = theme
            vim.notify("Markdown Preview theme: " .. theme, vim.log.levels.INFO)
          end, "Markdown Preview theme toggle")
        end,
      })
    end,
  },
}
