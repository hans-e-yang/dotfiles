# Dotfiles

Personal configs for nvim, tmux, i3, gtk (gruvbox theme), the Ghostty terminal
plus bootstrap tooling for dev toolchains (uv, nvm, sdkman) and starship.
Works on Debian/Ubuntu/Mint (apt), Fedora (dnf) and Arch (pacman).

Configs are symlinked into place with [GNU Stow](https://www.gnu.org/software/stow/),
so editing a live config **is** editing this repo — there is no pull-back script.
Each package is a canonical stow tree carrying its `$HOME`-relative path
(e.g. `nvim/.config/nvim/...`), so stowing against `$HOME` makes `~/.config/nvim`
a single symlink into the repo.

## Scripts

Three scripts, each with one job:

| script       | what it does                                                                 |
|--------------|------------------------------------------------------------------------------|
| `setup.sh`   | **Fresh-machine bootstrap** — run once on a new system. Detects the package manager (apt/dnf/pacman), installs core deps (git, stow, tmux, curl, zip, unzip, C toolchain, fontconfig), starship, the pinned nvim build, a Nerd Font, then asks about optional apps and symlinks the configs. |
| `install.sh` | **Symlink manager** — links (or `-D` unlinks) configs from the repo into `$HOME` via Stow. Safe to re-run: existing files that aren't already symlinks are moved to `*.bak-<timestamp>`. This is what you run on machines that already have setup done. |
| `apps.sh`    | **Optional toolchain installer** — y/n prompts for dev toolchains (uv, nvm, sdkman) and the ghostty terminal. Installs user-scoped into `$HOME` (Fedora `ghostty` comes from the Terra repo). Can be run standalone any time, not just during setup. |

In short: `setup.sh` once per new machine, `install.sh` on every machine (and after
`git pull`), `apps.sh` whenever you want another optional app.

## What gets linked

| package  | target                  | notes                                        |
|----------|-------------------------|----------------------------------------------|
| `nvim`   | `~/.config/nvim`        | lazy.nvim writes `lazy-lock.json` back here  |
| `tmux`   | `~/.config/tmux`        | TPM clones plugins into `tmux/plugins/` (gitignored) |
| `i3`     | `~/.config/i3`          | includes `picom.conf` + `i3status.conf`      |
| `gtk-3.0`| `~/.config/gtk-3.0`     |                                              |
| `ghostty`| `~/.config/ghostty`     | config + vendored `themes/gruvbox-dark`      |
| `gnome`  | `~/.config/gnome`       | `Super+x` power / `Super+c` shortcuts choosers |
| `home`   | `~`                     | portable, guarded `.bashrc` + `.bash_aliases` |

`i3`, `gtk-3.0`, `ghostty` and `gnome` are desktop configs: with no args they are
only linked after you answer `y` at a `[y/N]` prompt — never silently (non-tty
default: skip). The rest are safe anywhere.

The `gnome` package mimics i3's `$mod+x` (logout/reboot/shutdown/suspend) and
`$mod+c` (Firefox/Wi-Fi/Files) modal menus with zenity choosers, bound to
`Super+x` / `Super+c` via GNOME's media-key custom bindings (`setup-keybindings`
registers them idempotently and is called by the `install.sh` hook). It assumes
`zenity`, `nm-connection-editor` and `nautilus` are installed.

Linking `gnome` also offers to install [Pop Shell](https://github.com/pop-os/shell),
GNOME's tiling extension (Fedora: `dnf` package; apt/pacman: builds from source
per [System76's guide](https://support.system76.com/articles/pop-shell)). It is
GNOME-only, so the prompt warns and defaults to no — decline on i3 or any other
session.

## New machine

```sh
git clone https://github.com/hans-e-yang/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh            # distro detect → deps → starship → nvim → apps → symlink
```

- `./setup.sh --skip nvm` — don't install nvm
- `./setup.sh --install sdkman` — add sdkman without prompting for everything
- setup prompts y/n per app (Enter accepts the default); every action prints the
  exact command it runs
- Finish with `:Lazy restore` inside nvim, and `i3 -C` to validate i3

## Existing machine

```sh
cd ~/dotfiles && git pull
./install.sh                    # or: ./install.sh nvim tmux   (subset)
```

Existing files that aren't already symlinks are moved to `*.bak-<timestamp>`.

## Optional toolchains (`./apps.sh`)

| app       | default | installer                                      |
|-----------|---------|------------------------------------------------|
| `uv`      | yes     | astral installer; offers `uv python install`   |
| `nvm`     | yes     | pinned tag; offers `nvm install --lts`         |
| `sdkman`  | yes     | official installer; JVM/SDK candidates via `sdk` |
| `ghostty` | yes     | Fedora: Terra repo; Arch: `extra`; apt: guidance |

Use `./apps.sh list`, `./apps.sh install <name>`, or `./apps.sh --all`.
Add more apps by writing an installer function in `apps.sh` and registering it in
`APP_DEFAULT` / the name arrays.

### How installation works

Installers are user-scoped (no sudo except the distro package for `ghostty`) and
print the exact command before running it. `uv`/`nvm`/`sdkman` install into
`~/.local/bin`, `~/.nvm` and `~/.sdkman`; the repo-owned `~/.bashrc` activates
each one lazily and only if present, so nothing is appended to it at install time.
Already-installed tools are detected and skipped.

## Jupyter notebooks (jupynvim)

`sheng-tse/jupynvim` opens `.ipynb` files as real notebooks inside nvim. It needs
nvim >= 0.11, a kitty-graphics terminal (Ghostty, installed above), a registered
kernel, and ImageMagick 7 for animated GIFs. The kernel is a uv venv:

```sh
uv venv ~/.venvs/jupyter
uv pip install --python ~/.venvs/jupyter/bin/python ipykernel matplotlib
~/.venvs/jupyter/bin/python -m ipykernel install --user --name jupyter
```

The lazy `build` downloads the prebuilt `jupynvim-core` after verifying it against
the release `SHA256SUMS`; on Fedora that needs `shasum` (`perl-Digest-SHA`,
installed by `setup.sh`). Inside tmux, `allow-passthrough` (in `tmux.conf`) keeps
inline images working.

## Versions / pinned

- Neovim v0.12.5 (downloaded as `nvim-linux-x86_64.tar.gz` to `~/.local/share/nvim-linux-x86_64`, put on PATH by `~/.bashrc`)
- DejaVu Sans Mono Nerd Font v3.3.0 (installed to `~/.local/share/fonts`)
- nvm v0.40.7
- lazy.nvim plugins pinned via `lazy-lock.json`; run `:Lazy restore` after changes
- tmux 3.4, i3 4.23, picom v10 (as used on the reference machine)

## Others

Made on Linux Mint 22. Requires a Nerd Font for the status bar / nvim glyphs —
`setup.sh` installs DejaVu Sans Mono Nerd Font (the default terminal font on Fedora
Workstation). The i3 config uses `UbuntuNerdFont`; set the terminal/bar font to the
installed DejaVuSansMono Nerd Font if you use a different one. Also needs `feh`,
`picom`, `rofi`.
Much of the nvim config comes from [The Primeagen](https://youtu.be/w7i4amO_zaE)
and i3 from [The Linux Cast](https://youtu.be/77-tuFE_pGc).
