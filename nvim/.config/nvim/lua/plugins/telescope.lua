return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<cr>"},
    { "<C-p>", "<cmd>Telescope git_files<cr>"}
  },
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ps', function()
      builtin.grep_string({ search = vim.fn.input("Grep > ")})
    end)
  end
}
