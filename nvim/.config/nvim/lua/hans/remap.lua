-- Based on ThePrimeagen VIM Tutorial
-- Custom keybindings below
-- Uses "a register for auto bracket wrapping
-- Keybindings work in wsl2 ubuntu windows terminal
vim.g.mapleader = " "

local map = vim.keymap

-- Mapping save and explore mode
-- n for netrw
-- use <leader>q for nvimtree
map.set("n", "<leader>n", vim.cmd.Ex)
map.set("n", "<leader>w", ":w<cr>")

-- In Visual Mode: Pasting over selection won't change string in register.
map.set("x", "<leader>p", '"_dP')

-- Deletion without copying to register
map.set("n", "<leader>d", '"_d')
map.set("x", "<leader>d", '"_d')
map.set("n", "<leader>c", '"_c')
map.set("x", "<leader>c", '"_c')

-- Set yanking to clipboard
map.set("n", "<leader>y", '"+y')
map.set("n", "<leader>Y", '"+Y')
map.set("x", "<leader>y", '"+y')
map.set("x", "<leader>Y", '"+Y')

map.set("v", "<leader>y", '"+y')
map.set("v", "<leader>Y", '"+Y')

-- Moving in visual mode
map.set("v", "J", ":m '>+1<cr>gv=gv")
map.set("v", "K", ":m '<-2<cr>gv=gv")

-- Control Backspace like in VSCode
map.set("i", "<C-H>", "<C-W>")

-- Change behavior of enter and backspace in normal mode
-- map.set("n", "<cr>", "<C-M>")
map.set("n", "<CR>", "o<Esc>")
map.set("n", "<BS>", "i<C-U><Esc>")

map.set("i", "<C-z>", "<Esc>ui")
map.set("i", "<C-E>", "<Esc>A")

-- Mapping end for ruby, lua, etc
-- map.set("i", "<C-L>", "<CR><Tab><CR>end<Esc>ka")

-- Good <cr> behaviour when between tags
map.set("i", "<C-L>", "<CR><Esc>kA<Cr>")

-- Somehow, K is mapped to man, which I rarely use
-- This is to override that default behaviour
map.set("n", "K", ":lua vim.lsp.buf.hover()<CR>")

-- Tabout Behaviour
local taboutChars = {
  ["]"] = true,
  [")"] = true,
  ["}"] = true,
  [">"] = true,
  [";"] = true,
  [","] = true,
  ["'"] = true,
  ['"'] = true,
  ["`"] = true,
}

local function tabout()
  local _, c = unpack(vim.api.nvim_win_get_cursor(0))
  local next_char = vim.api.nvim_get_current_line():sub(c + 1, c + 1)

  if taboutChars[next_char] then
    return "<Right>"
  else
    return "<Tab>"
  end
end

map.set("i", "<Tab>", tabout, { silent = true, expr = true })

-- Delete pairs
local pair = {
  ["["] = "]",
  ["("] = ")",
  ["{"] = "}",
  ["'"] = "'",
  ['"'] = '"',
  ["<"] = ">",
  ["`"] = "`",
}

local function deletePair()
  local _, c = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local open = line:sub(c, c)
  local close = line:sub(c + 1, c + 1)
  if pair[open] == close then
    return "<Right><BS><BS>"
  else
    return "<BS>"
  end
end

map.set("i", "<BS>", deletePair, { silent = true, expr = true })

-- Wrap selection in brackets, backticks, etc..
for open, close in pairs(pair) do
  map.set("v", "<leader>" .. open, "c" .. open .. close .. "<ESC>hp")
end
