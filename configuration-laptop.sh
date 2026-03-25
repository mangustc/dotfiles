#!/usr/bin/env sh

# prepare
export DOTFILES_HOST="laptop"
export DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh
config base

# config
install_pkgs "$(trim_pkgs_file "./packages-$DOTFILES_HOST")"

# systemd-boot
config swap --size 8G

config acpi_call
config sysctl --opts "
net.ipv4.tcp_fin_timeout = 5
kernel.split_lock_mitigate = 0
kernel.nmi_watchdog = 0
kernel.soft_watchdog = 0
kernel.watchdog = 0
vm.max_map_count = 2147483642
"
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
config archscripts --dotfiles "$DOTFILES_DIR" --host "$DOTFILES_HOST"
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
config warp
config launch-windows
config zen-browser --search-engine
config zswap
config docker

cmd install -D -m 644 ./modules/steam-session/steam.desktop ~/.local/share/applications/steam.desktop

# late
config plasma-LATE
config boot-LATE --kernel-name linux
# end
print_orphan_packages
