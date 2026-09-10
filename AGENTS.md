# AGENTS.md

Personal dotfiles for Linux (Mint + i3 desktop, but Debian/Fedora/Arch supported).
No build, tests, lint, or CI — verification is manual on the target machine.
Configs are **symlinked** into `$HOME` from this repo via GNU Stow; the repo is the
source of truth, and editing a live config edits the repo directly.

## Scripts and data flow

- `setup.sh` — fresh-machine bootstrap, run from inside a clone. Distro-detects
  (`/etc/os-release` → apt/dnf/pacman), installs core deps (git, stow, tmux, curl,
  flatpak, C toolchain), starship (+ gruvbox-rainbow preset), pinned nvim v0.12.5
  tarball into `~/.local/share/nvim-linux-x86_64` (asset/dir renamed from
  `nvim-linux64` at v0.10; put on PATH by the repo-owned `~/.bashrc`) plus the
  tree-sitter CLI (`~/.local/bin`, required by nvim-treesitter `main`),
  installs a Nerd Font (`~/.local/share/fonts`), then calls `apps.sh`
  (forwarding args) and `install.sh`. Skipped if already present.
- `install.sh` — Stow wrapper. Every package is a canonical stow tree carrying its
  `$HOME`-relative path (`nvim/.config/nvim/...`, `home/.bashrc`, `home/.bash_aliases`),
  stowed with `-t $HOME`. No args = core packages (`nvim`, `tmux`, `home`) plus
  `i3`/`gtk-3.0` when an X11 session is detected; pass names explicitly or use
  `--all` to override. Existing non-symlink targets are moved to
  `*.bak-<timestamp>` first (before stow, since stow refuses to clobber). Hooks:
  clones TPM + installs plugins when tmux links (best-effort, non-fatal).
  `-D` unlinks. Nothing appends to `~/.bashrc` — the repo owns it (see layout).
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
`home/.bashrc` → `~/.bashrc` and `home/.bash_aliases` → `~/.bash_aliases`. The
repo-owned `~/.bashrc` is portable/guarded: it puts the pinned nvim + `~/.local/bin`
on PATH, sets `EDITOR`/`VISUAL`/`SUDO_EDITOR=nvim`, sources `~/.bash_aliases`, and
lazy-loads starship/nvm/completion — so nothing is appended to it at install time
and it works on Fedora/Arch too (Debian-only auto-source caveat no longer applies).
`home/.bash_aliases` was deduped when moved (old copy.sh appended → dupes). The
stale root-level `after/` dir (unused duplicate of `nvim/.config/nvim/after/`) was
removed on the 0.12 bump — edit only the copy under `nvim/`.

## Gotchas

- `tmux/.config/tmux/plugins/` is gitignored: TPM clones plugins through the
  `~/.config/tmux` symlink into the repo working tree.
- `~/.bashrc` is repo-owned (stowed from `home/.bashrc`), not appended to. All
  tool activation is guarded inside it (starship/nvm/PATH only fire if present).
  Put per-machine/per-distro overrides in `~/.bashrc.d/*` (sourced last), not by
  editing the stowed file with install-time appends.
- Version pins are deliberate: nvim v0.12.5 (setup.sh + PATH), nvm tag in apps.sh
  (`NVM_TAG`), lazy.nvim `lazy-lock.json`. After plugin changes run `:Lazy restore`.
- Plugin specs ending `.luab` (e.g. `nvim-ufo.luab`) are intentionally disabled —
  lazy.nvim only loads `.lua`. Rename to toggle.
- `i3/config` references `$HOME/.config/i3/picom.conf` and `i3status.conf`; keep
  both inside `i3/`.
- TPM init line (`run '~/.config/tmux/plugins/tpm/tpm'`) must stay the last line of
  `tmux/tmux.conf`.
- setup.sh needs sudo for package installs; apps.sh installs are user-scoped.
