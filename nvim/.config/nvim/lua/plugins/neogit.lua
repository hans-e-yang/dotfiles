return {
  "NeogitOrg/neogit",
  tag = "v0.0.1",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "sindrets/diffview.nvim",
  },
  cmd = "Neogit",
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>" },
    { "<leader>gc", "<cmd>Neogit commit<cr>" },
  },
  config = function()
    require("neogit").setup({
      kind = "floating",
      integrations = { diffview = true },
    })
  end,
}