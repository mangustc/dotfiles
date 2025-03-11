#!/bin/bash
set -x

echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia
modprobe vfio-pci

systemctl set-property --runtime -- system.slice AllowedCPUs=5
systemctl set-property --runtime -- user.slice AllowedCPUs=5
systemctl set-property --runtime -- init.scope AllowedCPUs=5

echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
