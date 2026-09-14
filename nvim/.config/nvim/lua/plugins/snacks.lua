-- VSCode-style tmux panels, powered by snacks.terminal (terminal module only).
-- Each panel runs a per-project tmux session so it persists across toggles/nvim restarts.

local function project_root()
  local cwd = vim.fn.getcwd()
  local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return out[1]
  end
  return cwd
end

local function project_key()
  local name = vim.fn.fnamemodify(project_root(), ":t"):gsub("[%.:%%%s]", "_")
  if name == "" then
    name = "root"
  end
  return name
end

-- tmux new-session -A attaches when the session already exists, else creates it.
local function session(role, command)
  local cmd = { "tmux", "new-session", "-A", "-s", ("nvim-%s-%s"):format(project_key(), role) }
  if command then
    table.insert(cmd, command)
  end
  return cmd
end

local function term_cmd()
  return session("term")
end

local function opencode_cmd()
  return session("opencode", "opencode")
end

local function term_opts(main)
  local opts = {
    cwd = project_root(),
    win = {
      position = "bottom",
      relative = "win",
      height = 0.25,
      min_height = 8,
    },
  }
  if main then
    opts.win.win = main
  end
  return opts
end

local function opencode_opts()
  return {
    cwd = project_root(),
    win = {
      position = "right",
      relative = "editor",
      width = 0.33,
      min_width = 60,
    },
  }
end

-- The window the bottom panel should attach to, so the layout stays L-shaped.
local function main_window()
  local cur = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(cur)].filetype ~= "snacks_terminal" then
    return cur
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_terminal" then
      return win
    end
  end
  return cur
end

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = { terminal = {} },
  config = function(_, opts)
    require("snacks").setup(opts)

    local terminal = require("snacks.terminal")

    vim.keymap.set("n", "<leader>tb", function()
      terminal.toggle(term_cmd(), term_opts())
    end, { desc = "Terminal: toggle bottom panel (tmux)" })

    vim.keymap.set("n", "<leader>to", function()
      terminal.toggle(opencode_cmd(), opencode_opts())
    end, { desc = "Terminal: toggle opencode panel (tmux)" })

    vim.keymap.set("n", "<leader>ta", function()
      local main = main_window()
      terminal.get(opencode_cmd(), opencode_opts()):show()
      terminal.get(term_cmd(), term_opts(main)):show()
    end, { desc = "Terminal: arrange VSCode workspace" })

    vim.keymap.set({ "n", "t" }, "<C-q>", function()
      if #vim.api.nvim_tabpage_list_wins(0) > 1 then
        vim.api.nvim_win_close(0, false)
      else
        vim.cmd.quitall()
      end
    end, { desc = "Close current split" })

    -- Always leave the panel for the nearest nvim window, whatever mode we're in.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "snacks_terminal",
      callback = function(ev)
        for key, dir in pairs({ ["<C-h>"] = "h", ["<C-j>"] = "j", ["<C-k>"] = "k", ["<C-l>"] = "l" }) do
          vim.keymap.set("n", key, "<cmd>wincmd " .. dir .. "<cr>", { buffer = ev.buf, silent = true })
          vim.keymap.set("t", key, "<C-\\><C-n><cmd>wincmd " .. dir .. "<cr>", { buffer = ev.buf, silent = true })
        end
      end,
    })
  end,
}
