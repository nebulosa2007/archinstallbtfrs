
## INSTALLING OTHER SOFT

#Upgrade system
pikaur -Syu

#console helpers
pikaur -S --needed htop mc ncdu ranger tmux micro
# speedread trash bat lsd bpytop

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

#Install bluetooth
pikaur -S bluez bluez-utils
sudo systemctl enable --now bluetooth

#Install cups
pikaur -S cups
sudo systemctl enable --now cups.service

#Bonus tuning (russian):
#https://github.com/ventureoo/ARU

#Install instance project
git clone https://github.com/nebulosa2007/archinstallbtfrs.git
cp -R archinstallbtfrs/instance . && rm -rf archinstallbtfrs
rm /home/$U/.bash_history; ln -s /home/$U/instance/bash_history /home/$U/.bash_history
ln -s /home/$U/instance/bash_aliases /home/$U/.bash_aliases
rm /home/$U/.bashrc && ln -s /home/$U/instance/bashrc /home/$U/.bashrc

#Install docker
pikaur -S docker
#for btrfs snapshots:
#https://forum.garudalinux.org/t/btrfs-docker-and-subvolumes/4601/14
sudo mkdir /etc/docker/ && printf '{\n\t"storage-driver": "overlay2"\t\n}\n' | sudo tee /etc/docker/daemon.json
sudo systemctl enable --now docker.service



#to be continued...

#todo
#http://wiki.rosalab.ru/ru/index.php/%D0%9F%D0%B5%D1%80%D0%B5%D0%BD%D0%BE%D1%81_%D1%81%D0%BD%D0%B0%D0%BF%D1%88%D0%BE%D1%82%D0%BE%D0%B2(snapshots)_btrfs_%D0%BD%D0%B0_%D0%B4%D1%80%D1%83%D0%B3%D0%BE%D0%B9_%D1%80%D0%B0%D0%B7%D0%B4%D0%B5%D0%BB_%D0%B2_%D0%BE%D1%82%D0%B4%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D0%BC_%D1%84%D0%B0%D0%B9%D0%BB%D0%B5
#
#mount /dev/sda1 /mnt
#btrfs subvolume delete /mnt/root_BACKUP.*
#btrfs subvolume delete /mnt/home_BACKUP.*
#btrfs subvolume snapshot /mnt/@ /mnt/root_BACKUP.$(date +%Y-%m-%d)_$(date +%T)
#btrfs subvolume snapshot /mnt/@home /mnt/home_BACKUP.$(date +%Y-%m-%d)_$(date +%T)
#umount /mnt
