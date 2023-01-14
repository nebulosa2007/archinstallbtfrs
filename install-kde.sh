## INSTALLING KDE

# Step 1. Install Xorg
sudo pacman -S xorg-server

# Install drivers 
# lspci -v | grep -A1 -e VGA -e 3D
# https://wiki.archlinux.org/title/Xorg#Driver_installation
# or all of them:
# sudo pacman -S xorg-drivers

# Testing X.Org Server
# sudo pacman -S xorg-xinit xterm
# startx

# Step 2.

## KDE Desktop minimal
sudo pacman -S plasma-desktop yakuake dolphin spectacle kate
sudo pacman -S --asdeps qt5-xmlpatterns plasma-browser-integration plasma-pa
# Optinal: time without PM/AM
# echo "LANG=en_US.UTF-8" | sudo tee /etc/default/locale
# sudo mkdir /etc/systemd/system/sddm.service.d/ && printf "[Service]\nEnvironmentFile=-/etc/default/locale" | sudo tee /etc/systemd/system/sddm.service.d/10-time.conf && sudo systemctl daemon-reload
sudo systemctl enable --now sddm

# Without networkmanager and bluez
pikaur -S --asdeps powerdevil-light

#Bluetooth support
sudo pacman -S --asdeps pulseaudio-bluetooth bluedevil
sudo systemctl enable --now bluetooth

#Android integration
sudo pacman -S --asdeps kdeconnect sshfs
