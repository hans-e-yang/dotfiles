vim.lsp.start({
  name = "markdown lsp",
  cmd = { os.getenv("HOME") .. "/.local/share/nvim/mdlsp" },
})
