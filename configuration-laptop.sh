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
config v226hql
config swap --size 8G
cmd sudo install -D -m 644 "$(writetext <<EOF
timeout 0
default arch.conf
console-mode keep
EOF
)" /boot/loader/loader.conf
cmd sudo install -D -m 644 "$(writetext <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=LABEL=arch-root rw nowatchdog zswap.enabled=1 zswap.compressor=zstd drm.edid_firmware=HDMI-A-1:edid/v226hql.bin
EOF
)" /boot/loader/entries/arch.conf

cmd sudo install -D -m 644 "$(writetext <<EOF
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_image="/boot/initramfs-linux.img"
EOF
)" /etc/mkinitcpio.d/linux.preset

cmd sudo install -D -m 644 "$(writetext <<EOF
[Login]
HandlePowerKey=sleep
EOF
)" /etc/systemd/logind.conf

cmd sudo install -D -m 644 "$(writetext <<EOF
LABEL=arch-root     	/         	ext4      	rw,relatime	0 1
LABEL=arch-boot     	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
EOF
)" /etc/fstab

config acpi_call
config sysctl --opts "
net.ipv4.tcp_mtu_probing = true
net.ipv4.tcp_fin_timeout = 5
kernel.split_lock_mitigate = 0
kernel.nmi_watchdog = 0
kernel.soft_watchdog = 0
kernel.watchdog = 0
kernel.sched_cfs_bandwidth_slice_u = 3000
kernel.sched_latency_ns = 3000000
kernel.sched_min_granularity_ns = 300000
kernel.sched_wakeup_granularity_ns = 500000
kernel.sched_migration_cost_ns = 50000
kernel.sched_nr_migrate = 128
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
config networkmanager
config nethandlerm
config ssh-agent
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

# end
print_orphan_packages
