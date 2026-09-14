return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<cr>" },
    { "<C-p>", "<cmd>Telescope git_files<cr>" },
    { "<leader>ps", function()
        require('telescope.builtin').grep_string({
          search = vim.fn.input("Grep > "),
          use_regex = false,
        })
      end, desc = "Grep string" },
  },
}
