-- Neovim plugins
return {
  -- Theme
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, 
    config = function()
      vim.cmd.colorscheme "catppuccin-macchiato"
    end
  },

  -- File explorer & Fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Treesitter (Syntax highlighting)
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "go" },
        highlight = { enable = true },
      })
    end
  },

  -- LSP support
  { "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require('lspconfig')

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright" },
        handlers = {
          function(server_name)
            lspconfig[server_name].setup({
              capabilities = capabilities,
            })
          end,
        }
      })
    end
  },
}
