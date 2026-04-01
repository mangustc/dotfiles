#!/usr/bin/env sh

# prepare
export DOTFILES_HOST="desktop"
export DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh
config base

# config
install_pkgs "$(trim_pkgs_file "./packages-$DOTFILES_HOST")"

# systemd-boot
config swap --size 16G
config v226hql --output-name HDMI-A-1

config module-blacklist --modules "
pcscpkr
iTCO_wdt
sp5100_tco
"
config earlyoom
config pipewire
config networkmanager --proxy --doh-https "https://dns.quad9.net/dns-query" --doh-ipv4 "9.9.9.9" --doh-ipv4-alt "149.112.112.112"
config nethandlerm
config ssh-agent
config launch-windows
config plasma
config ppd
config neovim
config zellij
config fish --zellij
config dualsense
config mangohud
config archscripts --dotfiles "$DOTFILES_DIR" --host "$DOTFILES_HOST"
config git
config flatpak --flatpaks "
"
config sddm --nopasswd --autologin
config scripts
config konsole
config yandex-disk
config desktop-fancontrol
config virt
config zen-browser --search-engine
config zswap
config docker

add_module_temp "boot-LATE" "$(writetext "nvidia.NVreg_EnableGpuFirmware=0")"

# late
config plasma-LATE
config boot-LATE --kernel-name linux
config hosts-LATE
config sysctl-LATE

# end
print_orphan_packages
