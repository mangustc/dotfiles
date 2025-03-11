#!/bin/bash
set -x

modprobe -r vfio-pci

echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Bind VTconsoles: might not be needed
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Restart Display Manager
# systemctl start display-manager

systemctl set-property --runtime -- system.slice AllowedCPUs=0-5
systemctl set-property --runtime -- user.slice AllowedCPUs=0-5
systemctl set-property --runtime -- init.scope AllowedCPUs=0-5

echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo balance_performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
