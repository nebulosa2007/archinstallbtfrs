## INSTALLING SWAY

sudo pacman -S sway dmenu grim mako swayidle swaylock swaybar otf-font-awesome
mkdir -p ~/.config/sway && cp /etc/sway/config ~/.config/sway/config
printf "\nif [ -z \$DISPLAY ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then\n  exec sway\nfi" >> ~/.bash_profile


#For Headless machines
sudo pacman -S swayvnc
