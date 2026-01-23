# Copy .config
mkdir $HOME/.config
cp -r ./{nvim,i3,tmux,gtk-3.0} $HOME/.config

# append .bash_aliases
touch $HOME/.bash_aliases
cat .bash_aliases >> $HOME/.bash_aliases
