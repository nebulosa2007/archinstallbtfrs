## INSTALLING SWAY

#Install sway environment
pikaur -S sway swaylock swayidle foot waybar xorg-xwayland swaybg grim slurp wl-clipboard ttf-font-awesome  mako jq sway-launcher-desktop qt5-wayland
mkdir -p ~/.config/sway && cp /etc/sway/config ~/.config/sway/config


#Enable login manager 
# pikaur -S ly && sudo systemctl enable --now ly
# or 
printf "\nif [ -z \$DISPLAY ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then\n  exec sway\nfi" >> ~/.bash_profile


#Other stuff 
pikaur -S polkit pipewire-media-session mesa xdg-utils blueberry seahorse

#For Headless machines
sudo pacman -S swayvnc

#TODO
# linked folders .config/{lavalauncher,sway,waybar}
# ln -s /home/ds/instance/config/sway 		/home/ds/.config/sway
# ln -s /home/ds/instance/config/waybar 		/home/ds/.config/waybar
