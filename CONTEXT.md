# dotfiles

Personal Linux dotfiles, symlinked into `$HOME` via GNU Stow. This glossary fixes the
vocabulary for the nvim panel/terminal setup so terms don't drift between config,
docs, and issues.

## Language

**Panel**:
A `snacks.terminal` split in nvim managed by the workspace keymaps. The bottom panel is
the *term* panel; the right panel is the *opencode* panel.
_Avoid_: terminal pane, sidebar, drawer

**Workspace**:
The L-shaped nvim layout of editor + right opencode panel + bottom term panel, produced
by `<leader>ta`. The layout is non-destructive: it adds panels without closing existing
splits.
_Avoid_: IDE mode, layout preset, dashboard

**Project key**:
The sanitized name of the current git repository root (fallback: the working directory
basename) that scopes a project's tmux sessions.
_Avoid_: project name, repo slug, workspace id
