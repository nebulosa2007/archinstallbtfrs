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

# Step 2. Install plasma, sddm
sudo pacman -S plasma-desktop sddm
sudo systemctl enable --now sddm
