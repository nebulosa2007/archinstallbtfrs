## INSTALLING GNOME AND TIMESHIFT

#pikaur - AUR helper, smallest one
sudo pacman -S --needed git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur


#Installing Gnome
sudo pacman -S gdm gnome gnome-tweaks gnome-software-packagekit-plugin gnome-extra xorg arc-icon-theme arc-gtk-theme xdg-user-dirs
sudo systemctl enable --now gdm

#Install timeshift
#sudo pacman -S --needed git
#git clone https://aur.archlinux.org/timeshift.git
#cd timeshift && makepkg -fsri && cd .. && rm -fr timeshift
#or 
pikaur -S timeshift

#git clone https://aur.archlinux.org/timeshift-autosnap.git
#cd timeshift-autosnap && makepkg -fsri && cd .. && rm -fr timeshift-autosnap
#or
pikaur -S timeshift-autosnap
#Check everything and create first snapshot
sudo timeshift-autosnap

#Install grub-btrfs
sudo pacman -S grub-btrfs
sudo grub-mkconfig -o /boot/grub/grub.cfg