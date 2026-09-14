# dotfiles

Personal Linux dotfiles, symlinked into `$HOME` via GNU Stow. This glossary fixes the
vocabulary for the nvim panel/terminal setup so terms don't drift between config,
docs, and issues.

## Language

**Panel**:
The right-side `snacks.terminal` split in nvim, toggled by `<leader>o`. It attaches
to the project's tmux session and takes half the editor width.
_Avoid_: terminal pane, sidebar, drawer

**Session window**:
A tmux window inside a project session. Each session has an `opencode` window and a
plain `term` window; switch between them with the tmux prefix (`C-Space n`).
_Avoid_: tab, pane, buffer

**Project key**:
The sanitized name of the current git repository root (fallback: the working directory
basename) that scopes a project's tmux session `nvim-<project>`.
_Avoid_: project name, repo slug, workspace id
