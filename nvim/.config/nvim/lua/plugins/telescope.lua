return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>pF", function()
        require('telescope.builtin').find_files({ hidden = true, no_ignore = true })
      end, desc = "Find files (incl. hidden/ignored)" },
    { "<C-p>", "<cmd>Telescope git_files<cr>" },
    { "<leader>ps", function()
        require('telescope.builtin').grep_string({
          search = vim.fn.input("Grep > "),
          use_regex = false,
        })
      end, desc = "Grep string" },
    { "<leader>pS", function()
        require('telescope.builtin').grep_string({
          search = vim.fn.input("Grep > "),
          use_regex = false,
          additional_args = { "--hidden", "--no-ignore" },
        })
      end, desc = "Grep string (incl. hidden/ignored)" },
  },
}
