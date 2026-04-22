#!/usr/bin/env sh

# prepare
export DOTFILES_HOST="laptop"
export DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh
config base
config yay

# config
install_pkgs "$(trim_pkgs_file "./packages-$DOTFILES_HOST")"

# systemd-boot
config swap --size 8G

config acpi_call
config module-blacklist --modules "
pcscpkr
iTCO_wdt
sp5100_tco
"
config earlyoom
config brightness
config pipewire
config networkmanager --proxy --doh-https "https://dns.quad9.net/dns-query" --doh-ipv4 "9.9.9.9" --doh-ipv4-alt "149.112.112.112"
config nethandlerm
config ssh-agent
config dualsense
config ppd
config plasma
config neovim
config fish --zellij
config archscripts
config git
config bluetooth
config flatpak --flatpaks "
"
config sddm
config scripts
config konsole
config zellij
config fonts
config yandex-disk
config launch-windows
config zen-browser --search-engine
config zswap
config docker
config discord
config ivo8c45 --output-name eDP-1

cmd install -D -m 644 ./modules/steam-session/steam.desktop ~/.local/share/applications/steam.desktop

# late
config plasma-LATE
config boot-LATE --kernel-name linux
config hosts-LATE
config nftables-LATE
config sysctl-LATE
config env-LATE

# end
print_orphan_packages
