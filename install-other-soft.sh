
## INSTALLING OTHER SOFT

#Upgrade system
sudo pacman -Syu

#console helpers
sudo pikaur -S htop mc ncdu inxi micro ranger trash bat lsd bpytop tmux
# speedread

#Optional old nvidia drivers
sudo pikaur nvidia-340xx-dkms
sudo cp /usr/share/nvidia-340xx/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf

#Installing Kodi
sudo pikaur -S kodi libcec
sudo usermod -aG uucp,lock $MAIN_USER
#reboot after required
#Youtube tuning -  https://djnapalm.ru/it/kodi/youtube.html
#SponsorsBlock - https://github.com/siku2/script.service.sponsorblock

#Bonus tuning (russian):
#https://docs.google.com/document/d/1IjTxl7LaPKJyRoLpGEhm4ptBhob_jRgLLQpMugS7qe8/edit

#to be continued...