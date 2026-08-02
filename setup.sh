# Install starship
curl -sS https://starship.rs/install.sh | sh
echo "eval \"$(starship init bash)\"" >> $HOME/.bashrc
source $HOME/.bashrc

# Use gruvbox-rainbow preset
starship preset gruvbox-rainbow -o ~/.config/starship.toml

# Install neovim 0.9.5
cd $HOME
curl -OL https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
tar xzvf nvim-linux64.tar.gz

# Add neovim alias
touch .bash_aliases
echo "alias nvim='~/nvim-linux64/bin/nvim" >> .bash_aliases
source .bash_aliases

# Install the config
git clone https://github.com/hans-e-yang/dotfiles.git dotfiles
cp -r dotfiles/.config ~

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install plugins
./.config/tmux/plugins/tpm/bin/install_plugins
