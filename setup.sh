#!/usr/bin/env bash
#
# setup.sh — fresh-machine bootstrap. Run from a clone of this repo:
#
#   git clone https://github.com/hans-e-yang/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./setup.sh [--skip a,b] [--install c,d]
#
# Steps: distro detect -> core deps -> starship -> pinned nvim -> apps (prompted)
#        -> symlink configs (install.sh). Flags are forwarded to apps.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
[ -d "$REPO_DIR/.git" ] || { echo "error: clone the repo first, then run setup.sh from inside it."; exit 1; }

NVIM_VERSION="0.9.5"

run_cmd() {
  echo "    -> $1"
  bash -c "$1"
}

# ------------------------------------------------------------ distro detect
PKG=""
detect_pkg_mgr() {
  if [ -r /etc/os-release ]; then . /etc/os-release; fi
  case "${ID:-}" in
    ubuntu|debian|linuxmint|linux|pop|elementary|neon|zorin) PKG=apt ;;
    fedora|rhel|centos|rocky|alma)                          PKG=dnf ;;
    arch|endeavouros|manjaro|garuda|cachyos)                PKG=pacman ;;
    *) echo "error: unsupported distro '${ID:-}'. Install git, stow, tmux, curl," \
           "flatpak and a C toolchain manually, then re-run."; exit 1 ;;
  esac
}

core_pkgs_apt()    { printf 'git stow tmux curl flatpak build-essential unzip fontconfig'; }
core_pkgs_dnf()    { printf 'git stow tmux curl flatpak gcc gcc-c++ make unzip fontconfig'; }
core_pkgs_pacman() { printf 'git stow tmux curl flatpak base-devel unzip fontconfig'; }

install_core() {
  case "$PKG" in
    apt)
      run_cmd "sudo apt-get update -qq"
      run_cmd "sudo apt-get install -y $(core_pkgs_apt)"
      ;;
    dnf)
      run_cmd "sudo dnf install -y $(core_pkgs_dnf)"
      ;;
    pacman)
      run_cmd "sudo pacman -S --needed --noconfirm $(core_pkgs_pacman)"
      ;;
  esac
}

# ------------------------------------------------------------ starship
install_starship() {
  command -v starship >/dev/null 2>&1 && { echo "  starship: already installed (skipping)"; return 0; }
  run_cmd "curl -sS https://starship.rs/install.sh | sh"
  if [ ! -e "$HOME/.config/starship.toml" ]; then
    mkdir -p "$HOME/.config"
    run_cmd "starship preset gruvbox-rainbow -o \"$HOME/.config/starship.toml\""
  fi
  if ! grep -qs 'dotfiles: starship' "$HOME/.bashrc"; then
    printf '\n# >>> dotfiles: starship >>>\neval "$(starship init bash)"\n# <<< dotfiles: starship <<<\n' >>"$HOME/.bashrc"
  fi
}

# ------------------------------------------------------------ nerd font
# DejaVu Sans Mono is the default terminal font on Fedora Workstation (and the
# fallback in i3/config), so the Nerd Font build of it is the safe default. Fonts
# land in ~/.local/share/fonts so no sudo is needed.
install_nerd_font() {
  local font=DejaVuSansMono version=3.3.0 dir="$HOME/.local/share/fonts/DejaVuSansMono"
  if fc-list 2>/dev/null | grep -qi "DejaVuSansMono Nerd Font"; then
    echo "  $font Nerd Font: already installed (skipping)"
    return 0
  fi
  local tmp; tmp="$(mktemp -d)"
  echo "  nerd font: downloading $font Nerd Font v$version"
  run_cmd "curl -fsSL -o \"$tmp/$font.zip\" \"https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/$font.zip\""
  mkdir -p "$dir"
  run_cmd "unzip -oq \"$tmp/$font.zip\" -d \"$dir\""
  run_cmd "fc-cache -f \"$dir\" >/dev/null"
  rm -rf "$tmp"
}

# ------------------------------------------------------------ nvim (pinned)
install_nvim() {
  local bin="$HOME/.local/share/nvim-linux64/bin/nvim"
  [ -x "$bin" ] && { echo "  nvim v$NVIM_VERSION: already installed (skipping)"; return 0; }
  local tmp; tmp="$(mktemp -d)"
  cd "$tmp"
  echo "  nvim: downloading v$NVIM_VERSION"
  run_cmd "curl -fsSL -o nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/nvim-linux64.tar.gz"
  tar xzf nvim-linux64.tar.gz
  mkdir -p "$HOME/.local/share"
  mv nvim-linux64 "$HOME/.local/share/"
  cd /
  rm -rf "$tmp"
}

# ------------------------------------------------------------ main
echo "==> detecting package manager"
detect_pkg_mgr
echo "    using: $PKG"

echo "==> installing core packages"
install_core

echo "==> installing starship"
install_starship

echo "==> installing nvim v$NVIM_VERSION"
install_nvim

echo "==> installing nerd font (DejaVu Sans Mono)"
install_nerd_font

echo "==> installing optional apps (uv, nvm, steam, discord)"
"$REPO_DIR/apps.sh" "$@"

echo "==> symlinking configs"
"$REPO_DIR/install.sh"

cat <<EOF

Done. Next steps:
  1. source ~/.bashrc (or open a new shell)
  2. in nvim run :Lazy restore to sync plugins to the lockfile
  3. if i3 was linked, validate with: i3 -C
EOF
