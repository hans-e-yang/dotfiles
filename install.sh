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
#   ./install.sh                 link core configs (nvim tmux home); on a
#                                desktop, each desktop config (i3, gtk-3.0,
#                                ghostty, gnome) is offered via a [y/N] prompt —
#                                nothing desktop-specific is linked silently
#                                (non-tty stdin: default answer = no)
#   ./install.sh [pkg ...]       link only the named packages
#                                (nvim tmux i3 gtk-3.0 ghostty gnome home)
#   ./install.sh --all           link every package, no prompts
#   ./install.sh -D [pkg ...]    unlink the given packages (stow -D); with no
#                                names, unlink core + currently linked desktop
#                                configs (no prompts)
#
# Anything already at a target path that is not one of our symlinks is moved
# aside to <path>.bak-<timestamp> before linking.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

HOME_PKG="home"

CORE_PKGS=(nvim tmux "$HOME_PKG")
DESKTOP_PKGS=(i3 gtk-3.0 ghostty gnome)

log()  { printf '\033[1;34m[link]\0033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[link]\0033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

ask() { # $1 prompt text, $2 default (y|n) -> 0 yes / 1 no
  local prompt="$1" dflt="$2" ans
  if [ ! -t 0 ]; then return "$([ "$dflt" = y ] && echo 0 || echo 1)"; fi
  printf '%s [%s] ' "$prompt" "$([ "$dflt" = y ] && echo Y/n || echo y/N)"
  read -r ans
  case "${ans:-$dflt}" in
    y|Y|yes) return 0 ;;
    *)       return 1 ;;
  esac
}

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

pkg_linked() { # $1 pkg -> 0 if every target path is a symlink into the repo
  paths_for_pkg "$1"
  local i
  for i in "${!CONFLICT_PATHS[@]}"; do
    if [ ! -L "${CONFLICT_PATHS[$i]}" ] \
       || [ "$(readlink -f "${CONFLICT_PATHS[$i]}")" != "${EXPECTED_SOURCES[$i]}" ]; then
      return 1
    fi
  done
  return 0
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

apply_gnome_keybindings() {
  local script="$HOME/.config/gnome/setup-keybindings"
  [ -x "$script" ] || return 0
  log "registering GNOME keybindings (Super+x power menu, Super+c shortcuts menu)"
  if ! "$script"; then
    echo "  [link] warning: keybinding setup failed (retry inside GNOME: $script)"
  fi
}

mode=link
pkgs=()
for a in "$@"; do
  case "$a" in
    --all) pkgs=(nvim tmux i3 gtk-3.0 ghostty gnome "$HOME_PKG") ;;
    -D)    mode=unlink ;;
    -h|--help) usage; exit 0 ;;
    --*)   die "unknown flag: $a (see ./install.sh --help)" ;;
    *)     pkgs+=("$a") ;;
  esac
done

if [ ${#pkgs[@]} -eq 0 ]; then
  pkgs=("${CORE_PKGS[@]}")
  for pkg in "${DESKTOP_PKGS[@]}"; do
    if [ "$mode" = unlink ]; then
      if pkg_linked "$pkg"; then pkgs+=("$pkg"); fi
    elif is_desktop; then
      if ask "link $pkg config into $HOME/.config/$pkg?" n; then pkgs+=("$pkg"); fi
    fi
  done
fi

for pkg in "${pkgs[@]}"; do
  if [ "$pkg" != "$HOME_PKG" ] && [ ! -d "$REPO_DIR/$pkg/.config/$pkg" ]; then
    die "no package '$pkg' in $REPO_DIR"
  fi
done

if [ "$mode" = unlink ]; then
  for pkg in "${pkgs[@]}"; do
    if pkg_linked "$pkg"; then
      unlink_pkg "$pkg"
    else
      log "$pkg is not linked (or not fully), skipping"
    fi
  done
  exit 0
fi

for pkg in "${pkgs[@]}"; do link_pkg "$pkg"; done

for pkg in "${pkgs[@]}"; do
  case "$pkg" in
    tmux)  ensure_tpm ;;
    gnome) apply_gnome_keybindings ;;
  esac
done

log "done. open a new shell for bash changes; run ':Lazy restore' inside nvim if plugins changed."
