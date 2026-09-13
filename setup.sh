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

NVIM_VERSION="0.12.5"
NVIM_DIR="$HOME/.local/share/nvim-linux-x86_64"

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
           "zip, unzip and a C toolchain manually, then re-run."; exit 1 ;;
  esac
}

core_pkgs_apt()    { printf 'git stow tmux curl zip unzip build-essential fontconfig'; }
# perl-Digest-SHA provides /usr/bin/shasum: Fedora splits it out, and jupynvim's
# lazy build hook needs it to verify the prebuilt jupynvim-core (it aborts on
# the missing command before falling back to sha256sum).
core_pkgs_dnf()    { printf 'git stow tmux curl zip unzip gcc gcc-c++ make fontconfig perl-Digest-SHA'; }
core_pkgs_pacman() { printf 'git stow tmux curl zip unzip base-devel fontconfig'; }

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
# Release assets are named nvim-linux-x86_64.* since v0.10 (was nvim-linux64.*).
install_nvim() {
  local bin="$NVIM_DIR/bin/nvim"
  if [ -x "$bin" ] && "$bin" --version 2>/dev/null | head -n1 | grep -q "v$NVIM_VERSION"; then
    echo "  nvim v$NVIM_VERSION: already installed (skipping)"
    return 0
  fi
  local tmp; tmp="$(mktemp -d)"
  cd "$tmp"
  echo "  nvim: downloading v$NVIM_VERSION"
  run_cmd "curl -fsSL -o nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/nvim-linux-x86_64.tar.gz"
  tar xzf nvim-linux-x86_64.tar.gz
  mkdir -p "$HOME/.local/share"
  rm -rf "$NVIM_DIR"
  mv nvim-linux-x86_64 "$HOME/.local/share/"
  cd /
  rm -rf "$tmp"
  if [ -d "$HOME/.local/share/nvim-linux64" ]; then
    echo "  removing stale pre-0.10 build ~/.local/share/nvim-linux64"
    rm -rf "$HOME/.local/share/nvim-linux64"
  fi
}

# ------------------------------------------------------------ tree-sitter CLI
# Required by nvim-treesitter (main branch) to generate parsers; installed
# user-scoped from the latest GitHub release into ~/.local/bin (on PATH via .bashrc).
install_ts_cli() {
  if command -v tree-sitter >/dev/null 2>&1; then
    echo "  tree-sitter-cli: already installed (skipping)"
    return 0
  fi
  local tmp; tmp="$(mktemp -d)"
  echo "  tree-sitter-cli: downloading latest"
  run_cmd "curl -fsSL -o \"$tmp/tree-sitter.gz\" https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz"
  gunzip "$tmp/tree-sitter.gz"
  chmod +x "$tmp/tree-sitter"
  mkdir -p "$HOME/.local/bin"
  mv "$tmp/tree-sitter" "$HOME/.local/bin/tree-sitter"
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

echo "==> installing tree-sitter CLI"
install_ts_cli

echo "==> installing nerd font (DejaVu Sans Mono)"
install_nerd_font

echo "==> installing optional apps (uv, mise, ghostty, fish)"
"$REPO_DIR/apps.sh" "$@"

echo "==> symlinking configs"
"$REPO_DIR/install.sh"

cat <<EOF

Done. Next steps:
  1. source ~/.bashrc, or open a new shell (fish reads config.fish itself)
  2. in nvim run :Lazy restore to sync plugins to the lockfile
  3. if i3 was linked, validate with: i3 -C
EOF
