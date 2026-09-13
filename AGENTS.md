# AGENTS.md

Personal dotfiles for Linux (Mint + i3 desktop, but Debian/Fedora/Arch supported).
No build, tests, lint, or CI — verification is manual on the target machine.
Configs are **symlinked** into `$HOME` from this repo via GNU Stow; the repo is the
source of truth, and editing a live config edits the repo directly.

## Scripts and data flow

- `setup.sh` — fresh-machine bootstrap, run from inside a clone. Distro-detects
  (`/etc/os-release` → apt/dnf/pacman), installs core deps (git, stow, tmux, curl,
  zip, unzip, C toolchain), starship (+ gruvbox-rainbow preset), pinned nvim v0.12.5
  tarball into `~/.local/share/nvim-linux-x86_64` (asset/dir renamed from
  `nvim-linux64` at v0.10; put on PATH by the repo-owned `~/.bashrc`) plus the
  tree-sitter CLI (`~/.local/bin`, required by nvim-treesitter `main`),
  installs a Nerd Font (`~/.local/share/fonts`), then calls `apps.sh`
  (forwarding args) and `install.sh`. Skipped if already present.
- `install.sh` — Stow wrapper. Every package is a canonical stow tree carrying its
  `$HOME`-relative path (`nvim/.config/nvim/...`, `home/.bashrc`, `home/.bash_aliases`),
  stowed with `-t $HOME`. No args = core packages (`nvim`, `tmux`, `home`); on a
  desktop, each desktop config (`i3`, `gtk-3.0`, `ghostty`, `gnome`) is offered via a `[y/N]`
  prompt and never linked silently (non-tty default: skip — this replaced the old
  auto-link on X11 detection). Pass names explicitly or use `--all` to skip prompts.
  Existing non-symlink targets are moved to
  `*.bak-<timestamp>` first (before stow, since stow refuses to clobber). Hooks:
  clones TPM + installs plugins when tmux links; when gnome links, registers our
  custom media-key bindings (`Super+x`/`Super+c`) and *offers* to install Pop
  Shell (all best-effort, non-fatal). Pop Shell is GNOME-only, so it is prompted
  with a warning and defaults to no (non-tty: skip; `--all` skips it entirely).
  Fedora uses the `dnf` package; apt/pacman build `pop-os/shell` from source into
  `~/.local/share/pop-shell-src` (branch picked from `gnome-shell --version`)
  and skip upstream's `restart-shell` target so install.sh never logs out.
  `-D` unlinks; with no names it unlinks core plus currently linked desktop configs
  (packages that aren't linked are skipped instead of erroring). Nothing appends to
  `~/.bashrc` — the repo owns it (see layout).
- `apps.sh` — optional dev toolchains with y/n prompts (Enter = manifest default;
  all default to yes: uv+nvm+sdkman+ghostty). Non-tty stdin falls back to
  defaults.
  `list`, `install <names>`, `--all`, `--skip a,b`, `--dry-run`. Every installer
  echoes its exact command before running and installs user-scoped:
  `uv` (astral installer, `~/.local/bin`), `nvm` (pinned tag, `~/.nvm`),
  `sdkman` (official installer, `~/.sdkman`; needs core dep `zip`/`unzip`), and
  `ghostty` via dnf/the Terra (Fyralabs) third-party repo — the
  officially documented Ghostty source — bootstrapped with
  `--nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever'`,
  pacman `extra`, apt prints manual guidance and skips. `.bashrc` activates
  uv/nvm/sdkman lazily and only if present. Register new apps in
  `APP_DEFAULT`, `TOOLCHAIN_NAMES`/`GUI_NAMES`, and an `install_<name>` function.
- There is **no update/pull-back script** — symlinks removed that need.

## Stow package layout

Each repo-root dir is one stow package carrying its `$HOME`-relative tree, so stowing
with `-t $HOME` yields a single symlink per config: `nvim/.config/nvim/...` →
`~/.config/nvim`; `i3/.config/i3/{config,picom.conf,i3status.conf}` → `~/.config/i3`;
`gtk-3.0/.config/gtk-3.0/settings.ini`; `ghostty/.config/ghostty/{config,themes/*}` →
`~/.config/ghostty` (Terra's ghostty rpm ships no themes, so `themes/gruvbox-dark` is
vendored in-repo); `tmux/.config/tmux/tmux.conf`;
`gnome/.config/gnome/{power-menu,shortcuts-menu,setup-keybindings}` → `~/.config/gnome`
(GNOME lacks i3's modal keybindings, so `Super+x`/`Super+c` pop zenity choosers that
mirror i3's exit/shortcuts modes; `setup-keybindings` idempotently registers them as
media-key custom bindings, forces 10 static workspaces and binds
`Super+1..0`/`Super+Shift+1..0` to switch/move (unbinding the dash's `Super+<n>`
app-launchers so i3 muscle memory carries over), and is invoked by the install.sh
hook);
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
- nvim Jupyter support is `jupynvim` (spec: `nvim/.config/nvim/lua/plugins/jupynvim.lua`).
  Its lazy `build` hook downloads the prebuilt Rust `jupynvim-core` into
  `~/.local/share/nvim/lazy/jupynvim/core/target/release/` (outside the stowed tree)
  after verifying it against the release `SHA256SUMS`. Fedora needs `perl-Digest-SHA`
  (added to setup.sh dnf core deps) for `shasum`; without it the build aborts before
  `chmod +x`, leaving a non-executable binary that fails at spawn with ENOENT. The
  kernel comes from `~/.venvs/jupyter` (uv + ipykernel, registered user kernelspec
  `jupyter`); inline images need Ghostty/kitty graphics plus tmux `allow-passthrough`
  (set in `tmux.conf`). Tree-sitter langs live in `plugins/treesitter.lua`.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues (`hans-e-yang/dotfiles`), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
