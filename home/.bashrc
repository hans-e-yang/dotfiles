# ~/.bashrc — owned by this dotfiles repo (symlinked via the `home` stow package).
#
# Portable across Debian/Ubuntu/Mint, Fedora and Arch. Every section is guarded,
# so a missing tool never errors and nothing here mutates itself at install time.
# For per-machine / per-distro tweaks drop files in ~/.bashrc.d/ (sourced last)
# instead of appending to this file.

# --------------------------------------------------------------- environment
# Kept above the interactive guard so login shells and non-interactive children
# (git, sudo, cron) inherit it too. All idempotent, so re-sourcing is safe.

# Prepend a dir to PATH only if it isn't already present.
_path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

# Put the pinned nvim build on PATH (installed by setup.sh) so `nvim` is a real
# command everywhere, not just an interactive alias.
[ -d "$HOME/.local/share/nvim-linux64/bin" ] && _path_prepend "$HOME/.local/share/nvim-linux64/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/bin"
export PATH

# Editor — nvim is now on PATH; only set it when actually available so tools
# fall back to their default (vi) on a machine without it.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim VISUAL=nvim SUDO_EDITOR=nvim
fi

# nvm — loaded lazily only if apps.sh installed it.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ----------------------------------------------------------- interactive-only
# Skip prompt/history/completion/alias setup in non-interactive shells.
case $- in
  *i*) ;;
  *) return ;;
esac

# History
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Resize tracking + colorized `ls`
shopt -s checkwinsize
if [ -x /usr/bin/dircolors ]; then
  test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
fi

# Aliases (repo-owned home/.bash_aliases)
[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"

# Bash completion (path differs across distros; guarded)
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Starship prompt (installed by setup.sh)
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Per-machine / per-distro drop-ins, sourced last so they can override.
if [ -d "$HOME/.bashrc.d" ]; then
  for _rc in "$HOME/.bashrc.d/"*; do
    [ -f "$_rc" ] && . "$_rc"
  done
  unset _rc
fi
