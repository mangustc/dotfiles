#!/usr/bin/env sh

if [ "$(whoami)" = "root" ]; then
	>2& echo "run this script as user"
	exit 1
fi

sudo sbctl create-keys
sudo sbctl enroll-keys -m
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo mkinitcpio -P
