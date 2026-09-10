#!/usr/bin/env bash
#
# apps.sh — install optional toolchains and apps with y/n confirmation.
#
# Usage:
#   ./apps.sh                    prompt for each app (Enter accepts the default)
#   ./apps.sh list               show which apps are already installed
#   ./apps.sh install a b        install named apps with no prompts
#   ./apps.sh --all              install everything with no prompts
#   ./apps.sh --skip a,b         prompt for everything except a and b
#   ./apps.sh --dry-run          print commands instead of running them
#
# Defaults: uv and nvm default to yes, GUI apps (steam, discord) default to no.
# Every action prints the exact command it runs.
set -euo pipefail

HOME_DIR="$HOME"
NVM_TAG="v0.40.7"          # pinned nvm release
UV_URL="https://astral.sh/uv/install.sh"

TOOLCHAIN_NAMES=(uv nvm)
GUI_NAMES=(steam discord)

# name:default (y/n)
declare -A APP_DEFAULT=([uv]=y [nvm]=y [steam]=n [discord]=n)
declare -A APP_LABEL=([uv]="uv (python package/version manager)" [nvm]="nvm (node version manager)" [steam]=Steam [discord]=Discord)

SKIPS=()
DRY_RUN=0

log()  { printf '\033[1;34m[apps]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[apps]\033[0m %s\n' "$*" >&2; exit 1; }

PM=""
detect_pm() {
  if [ -r /etc/os-release ]; then . /etc/os-release; fi
  case "${ID:-}" in
    ubuntu|debian|linuxmint|linux|pop|elementary|neon|zorin) PM=apt ;;
    fedora|rhel|centos|rocky|alma)                          PM=dnf ;;
    arch|endeavouros|manjaro|garuda|cachyos)                PM=pacman ;;
    *) PM=none ;;
  esac
}

known() { [ -n "${APP_DEFAULT[$1]:-}" ]; }

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

run_cmd() { # $1 exact command string
  echo "    -> $1"
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  bash -c "$1"
}

# ---------------------------------------------------------------- uv
install_uv() {
  local bin="$HOME_DIR/.local/bin/uv"
  if command -v uv >/dev/null 2>&1 || [ -x "$bin" ]; then
    echo "  $1: already installed (skipping)"
    return 0
  fi
  run_cmd "curl -LsSf $UV_URL | sh"
  if ask "  install latest Python via uv?" y; then
    run_cmd "$bin python install"
  fi
}

# ---------------------------------------------------------------- nvm
install_nvm() {
  if [ -s "$HOME_DIR/.nvm/nvm.sh" ]; then
    echo "  $1: already installed (skipping)"
    return 0
  fi
  run_cmd "git clone --depth=1 --branch $NVM_TAG https://github.com/nvm-sh/nvm.git \"$HOME_DIR/.nvm\""
  if ask "  install Node LTS and set it as the default?" y; then
    run_cmd ". \"$HOME_DIR/.nvm/nvm.sh\" && nvm install --lts && nvm alias default 'lts/*'"
  fi
}

# ------------------------------------------------- GUI apps (native PM first)
# Steam: apt->steam-installer (Mint enables multiverse), dnf->steam (RPM Fusion
# nonfree), pacman->steam. Discord: pacman->discord, otherwise flatpak only.

install_steam() {
  case "$PM" in
    apt)    pkg_or_flatpak "$1" "sudo apt-get install -y steam-installer" com.valvesoftware.Steam ;;
    dnf)    enable_rpmfusion "$1"
            pkg_or_flatpak "$1" "sudo dnf install -y steam" com.valvesoftware.Steam ;;
    pacman) pkg_or_flatpak "$1" "sudo pacman -S --needed --noconfirm steam" com.valvesoftware.Steam ;;
    *)      flatpak_install "$1" com.valvesoftware.Steam ;;
  esac
}

# RPM Fusion nonfree is not enabled by default on Fedora; steam needs it.
enable_rpmfusion() {
  if dnf repolist 2>/dev/null | grep -q '^rpmfusion-nonfree'; then return 0; fi
  local ver
  ver="$(rpm -E %fedora 2>/dev/null || echo "rawhide")"
  run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$ver.noarch.rpm"
  run_cmd "sudo dnf config-manager --set-enabled rpmfusion-nonfree"
  run_cmd "sudo dnf repolist"
}

install_discord() {
  flatpak_install "$1" com.discordapp.Discord
}

pkg_or_flatpak() { # $1 name, $2 native cmd, $3 flatpak id
  if run_cmd "$2"; then
    echo "  $1: installed via package manager"
  else
    echo "  $1: native install failed — falling back to flatpak"
    flatpak_install "$1" "$3"
  fi
}

flatpak_install() { # $1 name, $2 flatpak id
  local app_id="$2"
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "  $1: flatpak not found and no native package — run setup.sh first (it installs flatpak)"
    return 0
  fi
  if is_installed "$1"; then
    echo "  $1: already installed (skipping)"
    return 0
  fi
  if ! flatpak remotes --user 2>/dev/null | awk '{print $1}' | grep -qx flathub; then
    run_cmd "flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
  fi
  run_cmd "flatpak install --user -y flathub $app_id"
}

run_app() { # $1 name
  case "$1" in
    uv)      install_uv "$1" ;;
    nvm)     install_nvm "$1" ;;
    steam)   install_steam "$1" ;;
    discord) install_discord "$1" ;;
    *) die "no installer for '$1'" ;;
  esac
}

is_installed() { # $1 name
  case "$1" in
    uv)      command -v uv >/dev/null 2>&1 || [ -x "$HOME_DIR/.local/bin/uv" ] ;;
    nvm)     [ -s "$HOME_DIR/.nvm/nvm.sh" ] ;;
    steam)   command -v steam >/dev/null 2>&1 \
               || { command -v flatpak >/dev/null 2>&1 && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; } ;;
    discord) command -v flatpak >/dev/null 2>&1 && flatpak info com.discordapp.Discord >/dev/null 2>&1 ;;
    *)       return 1 ;;
  esac
}

skipped() { # $1 name
  for s in "${SKIPS[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

do_list() {
  printf '%-8s %-9s %s\n' APP STATE DESCRIPTION
  for name in "${TOOLCHAIN_NAMES[@]}" "${GUI_NAMES[@]}"; do
    local state=missing
    is_installed "$name" && state=installed
    printf '%-8s %-9s %s\n' "$name" "$state" "${APP_LABEL[$name]}"
  done
}

cmd=prompt
parsed_install=()
while [ $# -gt 0 ]; do
  case "$1" in
    list)     cmd=list ;;
    --all)    cmd=all ;;
    install)  cmd=install; shift; parsed_install=("$@"); break ;;
    --skip)   shift
              IFS=',' read -r -a SKIPS <<< "$1"
              ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1 (see ./apps.sh --help)" ;;
  esac
  shift
done

case "$cmd" in
  list)
    detect_pm
    do_list
    ;;
  install)
    detect_pm
    [ ${#parsed_install[@]} -gt 0 ] || die "usage: ./apps.sh install <name> [name ...]"
    for name in "${parsed_install[@]}"; do
      known "$name" || die "unknown app '$name' (known: ${TOOLCHAIN_NAMES[*]} ${GUI_NAMES[*]})"
      if is_installed "$name"; then
        echo "  $name: already installed (skipping)"
      else
        run_app "$name"
      fi
    done
    ;;
  all)
    detect_pm
    for name in "${TOOLCHAIN_NAMES[@]}" "${GUI_NAMES[@]}"; do
      is_installed "$name" || run_app "$name"
    done
    ;;
  prompt)
    detect_pm
    for name in "${TOOLCHAIN_NAMES[@]}" "${GUI_NAMES[@]}"; do
      skipped "$name" && continue
      if is_installed "$name"; then
        echo "  ${name}: already installed (skipping)"
        continue
      fi
      dflt="${APP_DEFAULT[$name]}"
      if ask "  install ${APP_LABEL[$name]}?" "$dflt"; then
        run_app "$name"
      fi
    done
    ;;
esac
