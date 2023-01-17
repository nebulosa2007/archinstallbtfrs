## INSTALLING KDE

# Step 1. Install Xorg
sudo pacman -S xorg-server

# Install drivers 
# lspci -v | grep -A1 -e VGA -e 3D
# https://wiki.archlinux.org/title/Xorg#Driver_installation
# ATI + Intel
# sudo pacman -S xf86-video-ati mesa xf86-video-intel libva-intel-driver  libva-mesa-driver libva-vdpau-driver
# or all of them:
# sudo pacman -S xorg-drivers

# Testing X.Org Server
# sudo pacman -S xorg-xinit xterm
# startx

# Step 2.

## KDE Desktop minimal
sudo pacman -S plasma-desktop qt5-xmlpatterns plasma-browser-integration plasma-pa power-profiles-daemon kdeplasma-addons sddm sddm-kcm dolphin yakuake spectacle kate gwenview
# Optinal: time without PM/AM
# echo "LANG=en_US.UTF-8" | sudo tee /etc/default/locale
# sudo mkdir /etc/systemd/system/sddm.service.d/ && printf "[Service]\nEnvironmentFile=-/etc/default/locale" | sudo tee /etc/systemd/system/sddm.service.d/10-time.conf && sudo systemctl daemon-reload

# Network manager:
# Disable systemd-networkd and iwd if any:
# sudo systemctl stop systemd-networkd && sudo systemctl disable systemd-networkd
# sudo systemctl stop iwd && sudo systemctl disable iwd && sudo pacman -Rsn iwd
# sudo pacman -S powerdevil plasma-nm
# sudo systemctl enable --now systemd-resolved
# sudo systemctl enable --now NetworkManager
# nmtui
# OR:
# Without networkmanager and bluez
pikaur -S powerdevil-light

#Bluetooth support
sudo pacman -S pulseaudio-bluetooth bluedevil
sudo systemctl enable --now bluetooth

#Android integration
sudo pacman -S kdeconnect sshfs

sudo systemctl enable --now sddm
