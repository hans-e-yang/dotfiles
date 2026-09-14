-- VSCode-style right panel, powered by snacks.terminal (terminal module only).
-- One per-project tmux session hosts two windows (`opencode` + `term`), so both
-- persist across toggles/nvim restarts and are shareable from a normal terminal.

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

local function session_name()
  return ("nvim-%s"):format(project_key())
end

-- `new-session -A -d` creates the session when missing and is a no-op when it
-- already exists. The `term` window is added only if it isn't there yet.
local function ensure_session()
  local name = session_name()
  local cwd = project_root()
  vim.fn.system({ "tmux", "new-session", "-A", "-d", "-s", name, "-c", cwd, "-n", "opencode", "opencode" })
  local wins = vim.fn.systemlist({ "tmux", "list-windows", "-t", name, "-F", "#{window_name}" })
  if vim.v.shell_error ~= 0 or not vim.tbl_contains(wins, "term") then
    vim.fn.system({ "tmux", "new-window", "-t", name, "-c", cwd, "-n", "term" })
  end
  return name
end

local function panel_opts()
  return {
    cwd = project_root(),
    win = {
      position = "right",
      relative = "editor",
      width = 0.5,
      min_width = 60,
    },
  }
end

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = { terminal = { win = { wo = { winbar = "" } } } },
  config = function(_, opts)
    require("snacks").setup(opts)

    local terminal = require("snacks.terminal")

    vim.keymap.set("n", "<leader>o", function()
      terminal.toggle({ "tmux", "attach", "-t", ensure_session() }, panel_opts())
    end, { desc = "Terminal: toggle opencode/term panel (tmux)" })

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
