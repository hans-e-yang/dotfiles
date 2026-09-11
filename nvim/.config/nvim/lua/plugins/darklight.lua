return {
  "eliseshaffer/darklight.nvim",
  lazy = false,
  config = function()
    require("darklight").setup()
    vim.keymap.set("n", "<leader>tt", "<cmd>DarkLightSwitch<CR>", { desc = "Toggle light/dark mode" })
  end,
}
