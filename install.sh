#!/usr/bin/env bash
#
# install.sh — link this repo's configs into $HOME with GNU Stow.
#
# Packages are standard stow trees: each config package carries its
# $HOME-relative path (e.g. nvim/.config/nvim/...), so stowing it against
# $HOME makes ~/.config/nvim a symlink into this repo. The home package
# stows top-level dotfiles (home/.bashrc -> ~/.bashrc, home/.bash_aliases ->
# ~/.bash_aliases). ~/.bashrc sources ~/.bash_aliases itself, so nothing is
# appended to it at install time.
#
# Usage:
#   ./install.sh                 link default set (i3 + gtk-3.0 are added
#                                automatically when an X11 session is detected)
#   ./install.sh [pkg ...]       link only the named packages (nvim tmux i3 gtk-3.0 home)
#   ./install.sh --all           link every package, ignore environment detection
#   ./install.sh -D [pkg ...]    unlink the given/default packages (stow -D)
#
# Anything already at a target path that is not one of our symlinks is moved
# aside to <path>.bak-<timestamp> before linking.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

HOME_PKG="home"

CORE_PKGS=(nvim tmux "$HOME_PKG")
DESKTOP_PKGS=(i3 gtk-3.0)

log()  { printf '\033[1;34m[link]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[link]\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
  esac
done

command -v stow >/dev/null 2>&1 \
  || die "GNU stow not found. Install it (e.g. 'sudo apt install stow') or run setup.sh."

is_desktop() {
  [ -n "${DISPLAY:-}" ] \
    || [ "${XDG_SESSION_TYPE:-}" = x11 ] \
    || command -v i3 >/dev/null 2>&1
}

# conflict path(s) stow would create for a package under $HOME, plus the
# canonical repo path each should point at.
declare -a CONFLICT_PATHS EXPECTED_SOURCES

paths_for_pkg() { # $1 pkg
  CONFLICT_PATHS=()
  EXPECTED_SOURCES=()
  local entry
  if [ "$1" = "$HOME_PKG" ]; then
    shopt -s dotglob
    for entry in "$REPO_DIR/$HOME_PKG"/*; do
      CONFLICT_PATHS+=("$HOME/$(basename "$entry")")
      EXPECTED_SOURCES+=("$REPO_DIR/$HOME_PKG/$(basename "$entry")")
    done
    shopt -u dotglob
  else
    CONFLICT_PATHS+=("$HOME/.config/$1")
    EXPECTED_SOURCES+=("$REPO_DIR/$1/.config/$1")
  fi
}

backup_conflict() { # $1 path, $2 expected canonical source
  [ -e "$1" ] || [ -L "$1" ] || return 0
  if [ -L "$1" ] && [ "$(readlink -f "$1")" = "$2" ]; then return 0; fi
  local bak="$1.bak-$(date +%Y%m%d-%H%M%S)"
  log "moving existing $1 -> $bak"
  mv "$1" "$bak"
}

link_pkg() { # $1 pkg
  paths_for_pkg "$1"
  local i
  for i in "${!CONFLICT_PATHS[@]}"; do
    backup_conflict "${CONFLICT_PATHS[$i]}" "${EXPECTED_SOURCES[$i]}"
  done
  if [ "$1" != "$HOME_PKG" ]; then mkdir -p "$HOME/.config"; fi
  log "linking $1 -> $HOME"
  stow -d "$REPO_DIR" -t "$HOME" "$1"
}

unlink_pkg() { # $1 pkg
  log "unlinking $1"
  stow -d "$REPO_DIR" -t "$HOME" -D "$1"
}

ensure_tpm() {
  local tpm="$HOME/.config/tmux/plugins/tpm"
  if [ ! -s "$tpm/tpm" ]; then
    log "cloning TPM"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  log "installing tmux plugins"
  if ! "$tpm/bin/install_plugins"; then
    echo "  [link] warning: plugin install failed (retry with: tmux source ~/.config/tmux/tmux.conf; ~/.config/tmux/plugins/tpm/bin/install_plugins)"
  fi
}

mode=link
pkgs=()
for a in "$@"; do
  case "$a" in
    --all) pkgs=(nvim tmux i3 gtk-3.0 "$HOME_PKG") ;;
    -D)    mode=unlink ;;
    -h|--help) usage; exit 0 ;;
    --*)   die "unknown flag: $a (see ./install.sh --help)" ;;
    *)     pkgs+=("$a") ;;
  esac
done

if [ ${#pkgs[@]} -eq 0 ]; then
  pkgs=("${CORE_PKGS[@]}")
  is_desktop && pkgs+=("${DESKTOP_PKGS[@]}")
fi

for pkg in "${pkgs[@]}"; do
  if [ "$pkg" != "$HOME_PKG" ] && [ ! -d "$REPO_DIR/$pkg/.config/$pkg" ]; then
    die "no package '$pkg' in $REPO_DIR"
  fi
done

if [ "$mode" = unlink ]; then
  for pkg in "${pkgs[@]}"; do unlink_pkg "$pkg"; done
  exit 0
fi

for pkg in "${pkgs[@]}"; do link_pkg "$pkg"; done

for pkg in "${pkgs[@]}"; do
  case "$pkg" in
    tmux) ensure_tpm ;;
  esac
done

log "done. open a new shell for bash changes; run ':Lazy restore' inside nvim if plugins changed."
