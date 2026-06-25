#!/usr/bin/env sh

# prepare
export DOTFILES_HOST="laptop"
export DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh

config base
config network
config audio
config ivo8c45 --output-name eDP-1
config plasma
config fonts
config fish --zellij
config swap --size 8G
config zswap
config amd

# config
install_pkgs "$(trim_pkgs_file "./packages-$DOTFILES_HOST")"

config brightness
config ssh-agent
config dualsense
config neovim
config fish --zellij
config archscripts
config git
config bluetooth
config scripts
config konsole
config launch-windows
config zen-browser
config docker
config discord

# late
config plasma-LATE
config boot-LATE --kernel-name linux
config hosts-LATE
config nftables-LATE

cmd sudo install -D -m 644 "$(writetext <<EOF
LABEL=arch-root     	/         	ext4      	rw,relatime	0 1
LABEL=arch-boot     	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
EOF
)" /etc/fstab

# end
print_orphan_packages
