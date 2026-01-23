return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function ()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        endwise = { enable = true },
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "html", "typescript" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = false },
      })
    end
  },
  {
    "tree-sitter/tree-sitter-embedded-template"
  }, 
  {
    "tpope/vim-endwise"
  }
}
