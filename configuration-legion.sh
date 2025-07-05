#!/usr/bin/env sh

source ./base.sh

paru -S --needed - < ./packages-legion
paru -Qdtq | paru -Rns -
config neovim
config fish
config dualsense
config nethandlerm
config kitty
config mangohud
config ssh-agent
config archscripts "~/dotfiles" legion
