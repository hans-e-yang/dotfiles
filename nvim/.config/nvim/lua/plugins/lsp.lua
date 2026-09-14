return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {}, -- auto-installs ensure_installed + auto-enables installed servers via vim.lsp.enable
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local severity = vim.diagnostic.severity
      local icon = vim.fn.nr2char
      local diag_icons = {
        [severity.ERROR] = icon(0xf057), -- nf-fa-times_circle
        [severity.WARN] = icon(0xf071), -- nf-fa-exclamation_triangle
        [severity.INFO] = icon(0xf05a), -- nf-fa-info_circle
        [severity.HINT] = icon(0xf0eb), -- nf-fa-lightbulb_o
      }

      vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Diagnostics: show float" })
      vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Diagnostics: previous" })
      vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Diagnostics: next" })

      vim.diagnostic.config({
        severity_sort = true,
        update_in_insert = false,
        signs = { text = diag_icons },
        underline = { severity = { min = severity.WARN } },
        virtual_text = {
          spacing = 2,
          prefix = function(d) return diag_icons[d.severity] or "" end,
          format = function(d) return d.message end,
        },
        float = {
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
        },
        jump = {
          on_jump = function(_, bufnr) vim.diagnostic.open_float({ bufnr = bufnr }) end,
        },
      })

      vim.lsp.config("clangd", {
        cmd = { "clangd", "--header-insertion=never" },
      })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      { "L3MON4D3/LuaSnip" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "windwp/nvim-autopairs" },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = {
          -- toggle completion
          ["<Esc>"] = cmp.mapping.abort(),

          -- manually trigger completion
          ["<C-Space>"] = cmp.mapping.complete(),

          -- navigate the suggestion list (falls back to tabout when closed)
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item() else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item() else fallback() end
          end, { "i", "s" }),

          -- Confirm the selected item
          ["<CR>"] = cmp.mapping.confirm({ select = true }),

          -- navigate between snippet placeholder
          ["<C-a>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end
          end, { "i", "s" }),
          ["<C-d>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(1) then luasnip.jump(1) else fallback() end
          end, { "i", "s" }),
        },
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" } },
          { { name = "buffer" } }
        ),
      })
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}
