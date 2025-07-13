#!/usr/bin/env sh

cd "$(dirname "$0")"
source ./base.sh

# paru -S --needed - < ./packages-legion
# paru -Qdtq | paru -Rns -
config neovim
config fish
config dualsense
config nethandlerm
config kitty
config mangohud
config ssh-agent
config archscripts "~/dotfiles" legion
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
config zram
config git
config steam-session
