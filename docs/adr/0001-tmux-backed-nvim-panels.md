# tmux-backed nvim panels

We wanted a VSCode-like nvim layout: a persistent terminal on the bottom and an
`opencode` panel on the right. We chose to drive both with `snacks.terminal`, with each
panel running its own tmux session named `nvim-<project>-{term,opencode}`. The sessions
are created with `tmux new-session -A`, so re-opening a panel — or reopening nvim —
reattaches to the same project-scoped session instead of starting fresh. This makes the
panels persistent and shareable with a normal terminal, at the cost of nesting tmux
inside nvim.

## Consequences

- **Nested tmux**: when nvim itself runs inside tmux, each panel is a nested client. The
  inner tmux owns the `C-Space` prefix; use it for pane control inside a panel.
- **Panels hijack `C-h/j/k/l`**: buffer-local maps in `snacks_terminal` buffers always
  leave the panel for the nearest nvim window (in both terminal-insert and
  terminal-normal mode), overriding `vim-tmux-navigator`. Those keys are therefore not
  available to the program running inside the panel.
- **`opencode` is resolved from PATH** inside the tmux session. It is installed via mise,
  so the tmux server environment must include the mise shim path; otherwise the opencode
  panel fails to start.
- **snacks is installed terminal-only** (`opts = { terminal = {} }`); all other snacks
  modules stay disabled so they don't overlap the existing telescope/nvimtree setup.
