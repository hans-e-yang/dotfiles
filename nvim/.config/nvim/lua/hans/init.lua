require("hans.remap")
-- The Primeagen stuff
vim.o.tabstop = 2
vim.o.expandtab = true
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.autoindent = true
vim.o.smartindent = true

-- Idk this fixes indenting error
vim.o.indentexpr = ""

-- Folding
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldclose = ""

-- no wrapping
vim.opt.wrap = false

-- Mouse support: click to focus/scroll and drag borders/statusline to resize splits
vim.opt.mouse = "a"

vim.o.number = true
vim.o.relativenumber = true

-- Keep the sign column stable so diagnostics don't shift the text when they appear
vim.o.signcolumn = "yes"

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- highlighting when vim searching 
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.updatetime = 750
vim.opt.colorcolumn = "80"

-- Reload files changed outside nvim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})
