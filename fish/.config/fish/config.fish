# ~/.config/fish/config.fish — owned by this dotfiles repo (symlinked via the
# `fish` stow package). Fish reads this in every session, so environment setup
# lives at the top and interactive-only setup (prompt, abbreviations) is guarded.
# Bash parity lives in home/.bashrc — bash still runs scripts and `sudo -i`.

# --------------------------------------------------------------- environment
# fish_add_path is idempotent; -g keeps the addition to this session (config.fish
# runs every session anyway) instead of writing a universal variable.
fish_add_path -g ~/.local/bin ~/bin
if test -d ~/.local/share/nvim-linux-x86_64/bin
    fish_add_path -g ~/.local/share/nvim-linux-x86_64/bin
end

if command -q nvim
    set -gx EDITOR nvim VISUAL nvim SUDO_EDITOR nvim
end

# ----------------------------------------------------------- interactive-only
if status is-interactive
    # mise (polyglot version manager: Node, Java, ...; installed by apps.sh)
    command -q mise; and mise activate fish | source

    # Starship prompt (installed by setup.sh)
    command -q starship; and starship init fish | source

    # Abbreviations — mirror of home/.bash_aliases, fish-style (expand inline).
    abbr -a la 'ls -la'
    abbr -a rtmux 'tmux source ~/.config/tmux/tmux.conf'
    abbr -a rb 'source ~/.config/fish/config.fish'
    abbr -a ktmux 'tmux kill-server'
    abbr -a atmux 'tmux attach -t '
    abbr -a gitgraph 'git log --oneline --all --graph'
    abbr -a cnvim 'nvim ~/.config/nvim'
    abbr -a ctmux 'nvim ~/.config/tmux'
    abbr -a ci3 'nvim ~/.config/i3'
    abbr -a rpanel 'pkill xfce4-panel; sleep .5; xfce4-panel &'

    # Per-machine / per-distro drop-ins: fish auto-sources
    # ~/.config/fish/conf.d/*.fish, so no explicit loop is needed.
end
