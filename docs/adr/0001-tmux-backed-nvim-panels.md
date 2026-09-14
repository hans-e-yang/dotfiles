# tmux-backed nvim panels

We wanted a VSCode-like nvim layout: an `opencode` panel on the right, with a shell a
keystroke away. We drive it with `snacks.terminal` as a single right-side split at 50%
width, toggled by `<leader>o`. The split runs a per-project tmux session named
`nvim-<project>` that hosts two windows — `opencode` and a plain `term`. The session is
created with `tmux new-session -A` (the `term` window is added only if missing), so
re-opening the panel — or reopening nvim — reattaches to the same project-scoped session
instead of starting fresh. This makes the panel persistent and shareable with a normal
terminal (switch windows with the tmux prefix), at the cost of nesting tmux inside nvim.

## Consequences

- **Nested tmux**: when nvim itself runs inside tmux, the panel is a nested client. The
  inner tmux owns the `C-Space` prefix; use it to switch between the `opencode` and
  `term` windows.
- **Panels hijack `C-h/j/k/l`**: buffer-local maps in `snacks_terminal` buffers always
  leave the panel for the nearest nvim window (in both terminal-insert and
  terminal-normal mode), overriding `vim-tmux-navigator`. Those keys are therefore not
  available to the program running inside the panel.
- **`opencode` is resolved from PATH** inside the tmux session. It is installed via mise,
  so the tmux server environment must include the mise shim path; otherwise the opencode
  window fails to start.
- **snacks is installed terminal-only** (`opts = { terminal = {} }`); all other snacks
  modules stay disabled so they don't overlap the existing telescope/nvimtree setup.
