
## INSTALLING OTHER SOFT

#Upgrade system
pikaur -Syu

#console helpers
pikaur -S --needed htop mc ncdu ranger tmux micro
# speedread trash bat lsd bpytop

#Optional old nvidia drivers
pikaur nvidia-340xx-dkms
sudo cp /usr/share/nvidia-340xx/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf
printf "Section \"ServerFlags\"\n  Option \"IgnoreABI\" \"1\"\nEndSection\n" >> /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/ kms //' /etc/mkinitcpio.conf
sudo mkinitcpio -P

#Installing Kodi
pikaur -S kodi libcec
sudo usermod -aG uucp,lock $MAIN_USER
#reboot after required
#Youtube tuning -  https://djnapalm.ru/it/kodi/youtube.html
#SponsorsBlock - https://github.com/siku2/script.service.sponsorblock


#Install docker
pikaur -S docker
#for btrfs snapshots:
#https://forum.garudalinux.org/t/btrfs-docker-and-subvolumes/4601/14
sudo mkdir /etc/docker/ && printf '{\n\t"storage-driver": "overlay2"\t\n}\n' | sudo tee /etc/docker/daemon.json
sudo systemctl enable --now docker.service


#Bonus tuning (russian):
#https://github.com/ventureoo/ARU

#http://wiki.rosalab.ru/ru/index.php/%D0%9F%D0%B5%D1%80%D0%B5%D0%BD%D0%BE%D1%81_%D1%81%D0%BD%D0%B0%D0%BF%D1%88%D0%BE%D1%82%D0%BE%D0%B2(snapshots)_btrfs_%D0%BD%D0%B0_%D0%B4%D1%80%D1%83%D0%B3%D0%BE%D0%B9_%D1%80%D0%B0%D0%B7%D0%B4%D0%B5%D0%BB_%D0%B2_%D0%BE%D1%82%D0%B4%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D0%BC_%D1%84%D0%B0%D0%B9%D0%BB%D0%B5
