
## INSTALLING OTHER SOFT

#Upgrade system
pikaur -Syu

#console helpers
pikaur -S htop mc ncdu inxi micro ranger trash bat lsd bpytop tmux
# speedread

#Optional old nvidia drivers
pikaur nvidia-340xx-dkms
sudo cp /usr/share/nvidia-340xx/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf

#Installing Kodi
pikaur -S kodi libcec
sudo usermod -aG uucp,lock $MAIN_USER
#reboot after required
#Youtube tuning -  https://djnapalm.ru/it/kodi/youtube.html
#SponsorsBlock - https://github.com/siku2/script.service.sponsorblock

#Installing localepurge
pikaur -S localepurge
#tune after /etc/locale.nopurge
sudo sed -i 's/NoExtract   =/NoExtract   = usr\/share\/locale\/* !usr\/share\/locale\/en_US* !usr\/share\/locale\/locale.alias/' /etc/pacman.conf

#Install bluetooth
pikaur -S bluez bluez-utils
sudo systemctl enable --now bluetooth

#Install cups
pikaur -S cups
sudo systemctl enable --now cups.service

#Bonus tuning (russian):
#https://docs.google.com/document/d/1IjTxl7LaPKJyRoLpGEhm4ptBhob_jRgLLQpMugS7qe8/edit

#to be continued...