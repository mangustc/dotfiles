#!/usr/bin/env sh

# prepare
DOTFILES_HOST="legion"
DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh

# config
install_pkgs "$(trim_pkgs_file ./packages-legion)"

# systemd-boot
cmd sudo install -Dm644 "$(writetext <<EOF
timeout 0
default bazzite.conf
console-mode keep
EOF
)" /boot/loader/loader.conf
cmd sudo install -Dm644 "$(writetext <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=LABEL=arch-root rw
EOF
)" /boot/loader/entries/arch.conf
cmd sudo install -Dm644 "$(writetext <<EOF
title Arch Linux - Bazzite kernel
linux /vmlinuz-linux-bazzite
initrd /initramfs-linux-bazzite.img
options root=LABEL=arch-root rw nowatchdog fbcon=vc:2-6 amdgpu.sg_display=0 drm.edid_firmware=DP-3:edid/v226hql.bin
EOF
)" /boot/loader/entries/bazzite.conf

# mkinitcpio
cmd sudo install -Dm644 ./v226hql/v226hql.bin /usr/lib/firmware/edid/v226hql.bin
cmd sudo install -Dm644 ./v226hql/v226hql.conf /etc/mkinitcpio.conf.d/v226hql.conf
cmd sudo install -Dm644 "$(writetext <<EOF
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_image="/boot/initramfs-linux.img"
EOF
)" /etc/mkinitcpio.d/linux.preset
cmd sudo install -Dm644 "$(writetext <<EOF
ALL_kver="/boot/vmlinuz-linux-bazzite"
PRESETS=('default')
default_image="/boot/initramfs-linux-bazzite.img"
EOF
)" /etc/mkinitcpio.d/linux-bazzite.preset

cmd sudo ln -sf /usr/share/zoneinfo/Asia/Tomsk /etc/localtime
cmd sudo hwclock --systohc

cmd sudo install -Dm644 "$(writetext <<EOF
en_CA.UTF-8 UTF-8
en_CA ISO-8859-1
en_US.UTF-8 UTF-8
en_US ISO-8859-1
ru_RU.KOI8-R KOI8-R
ru_RU.UTF-8 UTF-8
ru_RU ISO-8859-5
EOF
)" /etc/locale.gen

cmd sudo install -Dm644 "$(writetext "LANG=en_US.UTF-8")" /etc/locale.conf
cmd sudo install -Dm644 "$(writetext "KEYMAP=dvorak")" /etc/vconsole.conf
cmd sudo install -Dm644 "$(writetext "arch")" /etc/hostname
cmd sudo install -Dm644 "$(writetext <<EOF
LABEL=arch-root     	/         	ext4      	rw,relatime	0 1
LABEL=arch-boot     	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
EOF
)" /etc/fstab

# disable legion go mouse since i have an adhd scrollwheel
cmd sudo install -Dm644 "$(writetext <<EOF
ACTION=="add", SUBSYSTEM=="hid", ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="61eb", RUN+="/bin/sh -c 'echo 1 > \"\$(dirname \"\$(head /sys/bus/hid/drivers/hid-multitouch/*:17EF:61EB.*/input/input*/name | grep -B 1 Mouse | head -n 1 | cut -d \" \" -f 2)\")/inhibited\"'"
EOF
)" /etc/udev/rules.d/99-disable-legion-mouse.rules


config networkmanager
config neovim
config fish
config dualsense
config nethandlerm
config mangohud
config ssh-agent
config archscripts $DOTFILES_DIR $DOTFILES_HOST
config sysctl "
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
config module-blacklist "
pcscpkr
iTCO_wdt
sp5100_tco
"
config zram 8196
config git
config steam-session
config hhd
config bluetooth
config flatpak "
io.github.ryubing.Ryujinx
net.rpcs3.RPCS3
"
config sddm nopasswd
config scripts
config brightness
config legion-go-sound
config lsfg
config konsole
config pipewire

# end
print_orphan_packages
