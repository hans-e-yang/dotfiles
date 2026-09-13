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
# Defaults: every tool defaults to yes and installs user-scoped.
# Every action prints the exact command it runs.
set -euo pipefail

HOME_DIR="$HOME"
NVM_TAG="v0.40.7"          # pinned nvm release
UV_URL="https://astral.sh/uv/install.sh"
SDKMAN_URL="https://get.sdkman.io"

TOOLCHAIN_NAMES=(uv nvm sdkman)
GUI_NAMES=(ghostty)

# name:default (y/n)
declare -A APP_DEFAULT=([uv]=y [nvm]=y [sdkman]=y [ghostty]=y)
declare -A APP_LABEL=([uv]="uv (python package/version manager)" [nvm]="nvm (node version manager)" [sdkman]="sdkman (JVM/SDK version manager)" [ghostty]="Ghostty (kitty-graphics terminal, used by jupynvim)")

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

# ---------------------------------------------------------------- sdkman
install_sdkman() {
  if [ -s "$HOME_DIR/.sdkman/bin/sdkman-init.sh" ]; then
    echo "  $1: already installed (skipping)"
    return 0
  fi
  run_cmd "export SDKMAN_DIR=\"$HOME_DIR/.sdkman\" && curl -s \"$SDKMAN_URL\" | bash"
}

# ------------------------------------------------- ghostty
# Ghostty (kitty-graphics terminal; hard dependency for jupynvim inline images).
# Fedora: install via Terra (Fyralabs) — the officially documented source at
# https://ghostty.org/docs/install/binary. Terra is a third-party rolling repo;
# --nogpgcheck applies only to the one-time terra-release bootstrap, the
# installed repo ships Terra's GPG key. Arch: extra/ghostty. apt: no official
# package, print guidance and skip (non-fatal).
enable_terra() {
  if dnf repolist 2>/dev/null | grep -q '^terra'; then return 0; fi
  local ver
  ver="$(rpm -E %fedora 2>/dev/null || echo "rawhide")"
  run_cmd "sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$ver' terra-release"
  run_cmd "sudo dnf repolist"
}

install_ghostty() {
  case "$PM" in
    dnf)    enable_terra
            run_cmd "sudo dnf install -y ghostty" ;;
    pacman) run_cmd "sudo pacman -S --needed --noconfirm ghostty" ;;
    *)      echo "  $1: no official apt package — see https://ghostty.org/docs/install/binary (skipping)"
            return 0 ;;
  esac
}

run_app() { # $1 name
  case "$1" in
    uv)      install_uv "$1" ;;
    nvm)     install_nvm "$1" ;;
    sdkman)  install_sdkman "$1" ;;
    ghostty) install_ghostty "$1" ;;
    *) die "no installer for '$1'" ;;
  esac
}

is_installed() { # $1 name
  case "$1" in
    uv)      command -v uv >/dev/null 2>&1 || [ -x "$HOME_DIR/.local/bin/uv" ] ;;
    nvm)     [ -s "$HOME_DIR/.nvm/nvm.sh" ] ;;
    sdkman)  [ -s "$HOME_DIR/.sdkman/bin/sdkman-init.sh" ] ;;
    ghostty) command -v ghostty >/dev/null 2>&1 ;;
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
