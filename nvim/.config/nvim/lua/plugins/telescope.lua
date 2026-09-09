return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.6',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<cr>"},
    { "<C-p>", "<cmd>Telescope git_files<cr>"},
    { "gd", "<cmd>Telescope lsp_definitions<cr>"},
    { "gr", "<cmd>Telescope lsp_references<cr>"}
  },
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ps', function()
      builtin.grep_string({ search = vim.fn.input("Grep > ")})
    end)
  end
}
