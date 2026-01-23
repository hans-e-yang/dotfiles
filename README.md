# Dotfiles
Personal dotfile configuration for i3, rofi, nvim, tmux, gtk with gruvbox color theme.
Uses I3bar and I3Status for bar, picom as compositor
I3 configuration also added, using I3bar and I3Status

## Prerequisites
- Requires installation of tpm in ~/.config/tmux/plugins/tpm
- Neovim and Lua installed in the system
- Requires 'UbuntuNerdFont'. Other nerd fonts can be used, specify in .config/i3/config
- feh, picom, rofi 

## Versions
- Neovim v0.9.5
- tmux 3.4
- i3 4.23
- picom v10

## How to use
1. Follow the following steps in the shell
```sh
# Run copy.sh to copy files into home, or do manually
./copy.sh

# Run setup.sh to download dependencies
. setup.sh
```

2. Enter nvim and enter `:Lazy restore` to use restore plugins to lockfile

## Others
Made on Linux Mint 22.
Much of the configuration and plugins are taken from this [The Primeagen youtube video](https://youtu.be/w7i4amO_zaE?si=9UdWkqHR-pVDz2Jv)
I3: [The Linux Cast](https://youtu.be/77-tuFE_pGc?si=VPIjEaDzWCzyxPND) + reading other's dotfiles
