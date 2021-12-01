
## INSTALLING OTHER SOFT

#Upgrade system
sudo pacman -Syu

#console helpers
sudo pikaur -S htop mc ncdu inxi micro

#Optional
sudo pikaur nvidia-340xx-dkms
sudo cp /usr/share/nvidia-340xx/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf

sudo pikaur -S kodi libcec
sudo usermod -aG uucp,lock $MAIN_USER
#reboot after required

#Bonus tuning (russian):
#https://docs.google.com/document/d/1IjTxl7LaPKJyRoLpGEhm4ptBhob_jRgLLQpMugS7qe8/edit

#to be continued...