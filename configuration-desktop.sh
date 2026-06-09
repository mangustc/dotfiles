#!/usr/bin/env sh

# prepare
export DOTFILES_HOST="desktop"
export DOTFILES_DIR="$(realpath "$(dirname "$0")")"
cd "$DOTFILES_DIR"
source ./base.sh

# config
install_pkgs "$(trim_pkgs_file "./packages-$DOTFILES_HOST")"

config base
config audio
config network
config ivo8c45 --output-name DP-1 --headless
config v226hql --output-name HDMI-A-1
config plasma --autologin --nopasswd
config fish --zellij

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

add_module_temp "boot-LATE" "$(writetext "zswap.enabled=0")"
add_module_temp "env-LATE" "$(writetext <<'EOF'
export ANDROID_HOME="$HOME/Library/Android/sdk"
EOF
)"

# late
config plasma-LATE
config boot-LATE --kernel-name linux-cachyos
config hosts-LATE
config nftables-LATE
config sysctl-LATE
config env-LATE

# end
print_orphan_packages
