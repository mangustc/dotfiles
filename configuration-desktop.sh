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
config nvidia

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
config zen-browser --search-engine
config docker
config sunshine --cuda
config discord
config gaming

cmd sudo install -D -m 755 "$(writetext <<'EOF'
export ANDROID_HOME="$HOME/Library/Android/sdk"
EOF
)" /etc/profile.d/dotfiles-android.sh

# late
config plasma-LATE
config boot-LATE --kernel-name linux
config hosts-LATE
config nftables-LATE

# end
print_orphan_packages
