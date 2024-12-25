#!/bin/false
# shellcheck shell=bash

## INSTALLING GNOME AND TIMESHIFT

#Installing Gnome
sudo pacman -S gdm gnome gnome-tweaks gnome-software-packagekit-plugin gnome-extra xorg arc-icon-theme arc-gtk-theme xdg-user-dirs
sudo systemctl enable --now gdm

#Install timeshift
#sudo pacman -S --needed git
#git clone https://aur.archlinux.org/timeshift.git
#cd timeshift && makepkg -fsri && cd .. && rm -fr timeshift
#or
paru -S timeshift

#git clone https://aur.archlinux.org/timeshift-autosnap.git
#cd timeshift-autosnap && makepkg -fsri && cd .. && rm -fr timeshift-autosnap
#or
paru -S timeshift-autosnap
#Check everything and create first snapshot
sudo timeshift-autosnap

#Install grub-btrfs
sudo pacman -S grub-btrfs
sudo grub-mkconfig -o /boot/grub/grub.cfg
