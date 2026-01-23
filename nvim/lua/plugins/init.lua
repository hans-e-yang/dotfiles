return {
  -- {
  --   dir = "~/nvim-plugins/tabout",
  --   name = "tabout",
  --   opts = {
  --     chars = {']', ')', '"', "'", ';', ',', ">"},
  --     taboutKey = '<Tab>'
  --   }
  -- },
  --    {
  --       "rose-pine/neovim",
  --       lazy = false,
  --        priority = 1000,
  --        config = function()
  --            vim.cmd("colorscheme rose-pine-moon")
  --            vim.api.nvim_set_hl(0, "Normal", {bg = "none"})
  --            vim.api.nvim_set_hl(0, "NormalFloat", {bg = "none"})
  --        end
  --    },
  -- Nightfly Color Scheme
  -- { "bluz71/vim-nightfly-colors",
  --   name = "nightfly",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd("colorscheme nightfly")
  --     vim.api.nvim_set_hl(0, "Normal", {bg = "none"})
  --     vim.api.nvim_set_hl(0, "NormalFloat", {bg = "none"})
  --   end
  -- },
  { "ellisonleao/gruvbox.nvim", priority = 1000 , config = true,
    init = 
      function()
        vim.o.background = "dark"
        vim.cmd([[colorscheme gruvbox]])
      end
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = { options = { theme = 'gruvbox-material' } }
  },
  -- Miscellaneous
  { "nvim-treesitter/playground" },
  { "ThePrimeagen/vim-be-good" },
  { "nvim-treesitter/nvim-treesitter-context" },

  -- Tmux Navigation
  { "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  -- Icon picker
  { "ziontee113/icon-picker.nvim",
    dependencies = {"stevearc/dressing.nvim"},
    config = function()
      require("icon-picker").setup({ disable_legacy_commands = true })

      local opts = { noremap = true, silent = true }

      vim.keymap.set("n", "<Leader>i", "<cmd>IconPickerNormal<cr>", opts)
      vim.keymap.set("n", "<Leader><Leader>y", "<cmd>IconPickerYank<cr>", opts) --> Yank the selected icon into register
      vim.keymap.set("i", "<C-i>", "<cmd>IconPickerInsert<cr>", opts)
    end
  },

  -- add this to your lua/plugins.lua, lua/plugins/init.lua,  or the file you keep your other plugins:
  {
    'numToStr/Comment.nvim',
    lazy = false,
    config = function()
      require('Comment').setup()
      local api = require('Comment.api')
      vim.keymap.set('i', '<C-_>', api.toggle.linewise.current)
    end
  }

}

