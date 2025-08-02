#!/usr/bin/env sh

cp ./pacman.conf /etc/pacman.conf
pacman -Syu

ln -sf /usr/share/zoneinfo/Asia/Tomsk /etc/localtime
hwclock --systohc

echo "en_CA.UTF-8 UTF-8
en_CA ISO-8859-1
en_US.UTF-8 UTF-8
en_US ISO-8859-1
ru_RU.KOI8-R KOI8-R
ru_RU.UTF-8 UTF-8
ru_RU ISO-8859-5" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "KEYMAP=dvorak" > /etc/vconsole.conf

echo "arch" > /etc/hostname

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
passwd
useradd -m -G audio,video,wheel,tty,kvm,input,network -s /bin/bash ivan
passwd ivan

bootctl install

pacman -S --needed base-devel git sudo
cd /home/ivan
sudo -u ivan git clone https://github.com/mangustc/dotfiles
sudo -u ivan mkdir git
cd ./git
sudo -u ivan git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
sudo -u ivan makepkg -si

cd /home/ivan/dotfiles
echo "logging in as ivan"
echo "now install configuration using ./configuration-HOST.sh"
exec su ivan
