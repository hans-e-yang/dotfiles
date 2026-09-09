return {
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    lazy = true,
    config = false,
    init = function()
      -- Disable automatic setup, we are doing it manually
      vim.g.lsp_zero_extend_cmp = 0
      vim.g.lsp_zero_extend_lspconfig = 0
    end,
    keys = {
      { "[d",
        function()
          vim.diagnostic.goto_prev()
          vim.diagnostic.open_float()
        end
      }, {
        "]d",
        function()
          vim.diagnostic.goto_next()
          vim.diagnostic.open_float()
        end
      }
    }
  },
  {
    'mason-org/mason.nvim',
    lazy = false,
    config = true,
  },

  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {'L3MON4D3/LuaSnip'},
      {'windwp/nvim-autopairs'}
    },
    config = function()
      -- Here is where you configure the autocompletion settings.
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_cmp()

      -- And you can configure cmp even more, if you want to.
      local cmp = require('cmp')
      local cmp_action = lsp_zero.cmp_action()
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')

      cmp.setup({
        formatting = lsp_zero.cmp_format({details = true}),
        mapping = {
          -- Navigate between completion item
          -- ['<C-m>'] = cmp.mapping.select_prev_item(),
          -- ['<C-n>'] = cmp.mapping.select_next_item(),

          -- toggle completion
          ['<Esc>'] = cmp.mapping.abort(),

          -- navigate between snippet placeholder
          ['<C-a>'] = cmp_action.luasnip_jump_backward(),
          ['<C-d>'] = cmp_action.luasnip_jump_forward(),

          -- Confirm item
          ['<Tab>'] = cmp.mapping.confirm({select = true}),
        },
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
      })
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
  },
  -- LSP
  {
    'neovim/nvim-lspconfig',
    version = "v1.8.0",
    cmd = {'LspInfo', 'LspInstall', 'LspStart'},
    event = {'BufReadPre', 'BufNewFile'},
    dependencies = {
      {'hrsh7th/cmp-nvim-lsp'},
      {'mason-org/mason-lspconfig.nvim', version = "v1.32.0"},
    },
    config = function()
      -- This is where all the LSP shenanigans will live
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_lspconfig()

      --- if you want to know more about lsp-zero and mason.nvim
      --- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({buffer = bufnr})
      end)

      require('mason-lspconfig').setup({
        ensure_installed = {},
        handlers = {
          -- this first function is the "default handler"
          -- it applies to every language server without a "custom handler"
          function(server_name)
            require('lspconfig')[server_name].setup({})
          end,

          -- this is the "custom handler" for `lua_ls`
          lua_ls = function()
            -- (Optional) Configure lua language server for neovim
            local lua_opts = lsp_zero.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
          end,

          -- Remove auto header insertion for 'clangd', annoying for c development
          clangd = function()
            require("lspconfig").clangd.setup({
              cmd = {"clangd", "--header-insertion=never"}
            })
          end,
        }
      })
    end
  },
  -- {
  --   "lewis6991/hover.nvim",
  --   config = function()
  --     require("hover").setup {
  --       init = function()
  --         -- Require providers
  --         require("hover.providers.lsp")
  --         -- require('hover.providers.gh')
  --         -- require('hover.providers.gh_user')
  --         -- require('hover.providers.jira')
  --         -- require('hover.providers.dap')
  --         -- require('hover.providers.fold_preview')
  --         -- require('hover.providers.diagnostic')
  --         -- require('hover.providers.man')
  --         -- require('hover.providers.dictionary')
  --         -- require('hover.providers.highlight')
  --       end,
  --       preview_opts = {
  --         border = 'single'
  --       },
  --       -- Whether the contents of a currently open hover window should be moved
  --       -- to a :h preview-window when pressing the hover keymap.
  --       preview_window = false,
  --       title = true,
  --       mouse_providers = {
  --         'LSP'
  --       },
  --       mouse_delay = 1000
  --     }
  --
  --     -- Setup keymaps
  --     vim.keymap.set("n", "K", require("hover").hover, {desc = "hover.nvim"})
  --     vim.keymap.set("n", "gK", require("hover").hover_select, {desc = "hover.nvim (select)"})
  --     vim.keymap.set("n", "<C-p>", function() require("hover").hover_switch("previous") end, {desc = "hover.nvim (previous source)"})
  --     vim.keymap.set("n", "<C-n>", function() require("hover").hover_switch("next") end, {desc = "hover.nvim (next source)"})
  --
  --     -- Mouse support
  --     vim.keymap.set('n', '<MouseMove>', require('hover').hover_mouse, { desc = "hover.nvim (mouse)" })
  --     vim.o.mousemoveevent = true
  --   end
  -- },
  -- {
  --   "pmizio/typescript-tools.nvim",
  --    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   opts = {},
  -- }
}
