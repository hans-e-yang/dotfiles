# AGENTS.md

Personal dotfiles for Linux (Mint + i3 desktop, but Debian/Fedora/Arch supported).
No build, tests, lint, or CI — verification is manual on the target machine.
Configs are **symlinked** into `$HOME` from this repo via GNU Stow; the repo is the
source of truth, and editing a live config edits the repo directly.

## Scripts and data flow

- `setup.sh` — fresh-machine bootstrap, run from inside a clone. Distro-detects
  (`/etc/os-release` → apt/dnf/pacman), installs core deps (git, stow, tmux, curl,
  flatpak, C toolchain), starship (+ gruvbox-rainbow preset), pinned nvim v0.9.5
  tarball into `~/.local/share/nvim-linux64` (aliased in `.bash_aliases`, not on
  PATH), installs a Nerd Font (`~/.local/share/fonts`), then calls `apps.sh`
  (forwarding args) and `install.sh`. Skipped if already present.
- `install.sh` — Stow wrapper. Every package is a canonical stow tree carrying its
  `$HOME`-relative path (`nvim/.config/nvim/...`, `home/.bash_aliases`), stowed with
  `-t $HOME`. No args = core packages (`nvim`, `tmux`, `home`) plus `i3`/`gtk-3.0`
  when an X11 session is detected; pass names explicitly or use `--all` to override.
  Existing non-symlink targets are moved to `*.bak-<timestamp>` first (before stow,
  since stow refuses to clobber). Hooks: clones TPM + installs plugins when tmux
  links (best-effort, non-fatal); appends a marker-guarded `source ~/.bash_aliases`
  block to `~/.bashrc` (`.bash_aliases` is only auto-sourced by Debian-family
  bashrc). `-D` unlinks.
- `apps.sh` — optional toolchains/apps with y/n prompts (Enter = manifest default;
  defaults: uv+nvm yes, steam+discord no). Non-tty stdin falls back to defaults.
  `list`, `install <names>`, `--all`, `--skip a,b`, `--dry-run`. Every installer
  echoes its exact command before running. GUI apps install via the native package
  manager when available (steam: apt `steam-installer` / dnf `steam` after enabling
  RPM Fusion nonfree, which is **not** enabled by default / pacman `steam`; discord:
  flatpak only), falling back to flatpak — which adds flathub
  as a **user** remote (`flatpak remotes --user`) since Mint's flathub is a system
  remote and `flatpak install --user` can't see it. Register new apps in
  `APP_DEFAULT`, `TOOLCHAIN_NAMES`/`GUI_NAMES`, and an `install_<name>` function.
- There is **no update/pull-back script** — symlinks removed that need.

## Stow package layout

Each repo-root dir is one stow package carrying its `$HOME`-relative tree, so stowing
with `-t $HOME` yields a single symlink per config: `nvim/.config/nvim/...` →
`~/.config/nvim`; `i3/.config/i3/{config,picom.conf,i3status.conf}` → `~/.config/i3`;
`gtk-3.0/.config/gtk-3.0/settings.ini`; `tmux/.config/tmux/tmux.conf`;
`home/.bash_aliases` → `~/.bash_aliases`. `home/.bash_aliases` was deduped when moved
(old copy.sh appended → dupes). The stale root-level `after/` dir is an unused
duplicate of `nvim/.config/nvim/after/` — edit the copy under `nvim/`.

## Gotchas

- `tmux/.config/tmux/plugins/` is gitignored: TPM clones plugins through the
  `~/.config/tmux` symlink into the repo working tree.
- `~/.bashrc` gets marker-guarded append blocks (`# >>> dotfiles: X >>>`) from
  install.sh (bash_aliases), apps.sh (nvm, `~/.local/bin` PATH) and setup.sh
  (starship). Keep the markers when changing them.
- Version pins are deliberate: nvim v0.9.5 (setup.sh + alias), nvm tag in apps.sh
  (`NVM_TAG`), lazy.nvim `lazy-lock.json`. After plugin changes run `:Lazy restore`.
- Plugin specs ending `.luab` (e.g. `lsp.luab`) are intentionally disabled —
  lazy.nvim only loads `.lua`. Rename to toggle.
- `i3/config` references `$HOME/.config/i3/picom.conf` and `i3status.conf`; keep
  both inside `i3/`.
- TPM init line (`run '~/.config/tmux/plugins/tpm/tpm'`) must stay the last line of
  `tmux/tmux.conf`.
- setup.sh needs sudo for package installs; apps.sh installs are user-scoped.
