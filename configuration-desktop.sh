#!/usr/bin/env sh

# prepare
export DOTFILES_HOST="desktop"
export DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh

config base
config network
config audio
config zram
config ivo8c45 --output-name DP-1 --headless
config v226hql --output-name HDMI-A-1
config plasma --nopasswd --autologin
config fonts
config fish --zellij
config nvidia --rebar

install_pkgs "$(trim_pkgs_file "./packages-$DOTFILES_HOST")"

config ssh-agent
config launch-windows
config neovim
config dualsense
config archscripts
config git
config scripts
config konsole
config virt --sunshine "enp4s0"
config zen-browser
config sunshine --cuda
config discord
config gaming

cmd sudo install -D -m 755 "$(writetext <<'EOF'
export JAVA_HOME=/opt/android-studio/jbr
export ANDROID_HOME="$HOME/Android/Sdk"
export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
export PATH="$HOME/.local/share/cargo/bin:$PATH"
EOF
)" /etc/profile.d/dotfiles-extra.sh

# late
config plasma-LATE
config boot-LATE --kernel-name linux
config hosts-LATE
config nftables-LATE

cmd sudo install -D -m 644 "$(writetext <<EOF
LABEL=arch-root     	/         	ext4      	rw,relatime	0 1
LABEL=arch-boot     	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
LABEL=arch-stuff   /mnt/arch-stuff   ext4   rw,relatime,nofail,X-mount.mkdir   0   2
EOF
)" /etc/fstab

# end
print_orphan_packages
