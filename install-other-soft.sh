## INSTALLING OTHER SOFT

U=ds

#Console useful programs
pikaur -Syu --needed htop mc ncdu ranger tmux micro lsd
#Optional: pikaur -S --needed speedread trash bat bpytop


#Cleaning/rebase apps in home folder:
#Firefox
# 1. https://wiki.archlinux.org/title/Firefox/Tweaks
# 2. move .mozilla folder in a proper place
cp -r ~/.mozilla ~/.config/mozilla && rm -rf ~/.mozilla && ln -s ~/.config/mozilla ~/.mozilla

#Telegram Desktop
cp -r ~/.local/share/TelegramDesktop ~/.config/TelegramDesktop && rm -fr ~/.local/share/TelegramDesktop && ln -s ~/.config/TelegramDesktop ~/.local/share/TelegramDesktop
#Moving cache in proper place
mkdir -p  ~/.cache/Telegram\ Desktop && cp -r ~/.config/TelegramDesktop/tdata/user_data ~/.cache/Telegram\ Desktop/user_data && rm -fr ~/.config/TelegramDesktop/tdata/user_data && ln -s ~/.cache/Telegram\ Desktop/user_data ~/.config/TelegramDesktop/tdata/user_data

#Youtube Music https://aur.archlinux.org/packages/youtube-music-bin
#Moving cache in proper place
cp -r ~/.config/YouTube\ Music/Cache ~/.cache/YouTube\ Music && rm -fr ~/.config/YouTube\ Music/Cache && ln -s ~/.cache/YouTube\ Music ~/.config/YouTube\ Music/Cache
#Moving .pki in proper place
cp -r ~/.pki ~/.local/share/pki && rm -fr ~/.pki && ln -s ~/.local/share/pki ~/.pki




#Credits: https://ventureo.codeberg.page/source/generic-system-acceleration.html
#Lower latency due system boot:
pikaur -S rng-tools
sudo systemctl enable --now rngd



#Optional old nvidia drivers
pikaur -S linux-headers nvidia-340xx-dkms
sudo cp /usr/share/nvidia-340xx/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/Driver "nvidia"/Driver "nvidia"\n  Option "NoLogo" "1"/' /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/ kms / /' /etc/mkinitcpio.conf
sudo mkinitcpio -P


#Installing Kodi with autologin
pikaur -S kodi libcec lightdm
sudo usermod -aG uucp,lock $U
echo "mesa_glthread=true" | sudo tee -a /etc/environment
sudo sed -i "s/^\[Seat:\*\]$/\[Seat:\*\]\npam-service=lightdm-autologin\nautologin-user=$U\nautologin-user-timeout=0\nuser-session=kodi/" /etc/lightdm/lightdm.conf
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
#https://ventureo.codeberg.page

#http://wiki.rosalab.ru/ru/index.php/%D0%9F%D0%B5%D1%80%D0%B5%D0%BD%D0%BE%D1%81_%D1%81%D0%BD%D0%B0%D0%BF%D1%88%D0%BE%D1%82%D0%BE%D0%B2(snapshots)_btrfs_%D0%BD%D0%B0_%D0%B4%D1%80%D1%83%D0%B3%D0%BE%D0%B9_%D1%80%D0%B0%D0%B7%D0%B4%D0%B5%D0%BB_%D0%B2_%D0%BE%D1%82%D0%B4%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D0%BC_%D1%84%D0%B0%D0%B9%D0%BB%D0%B5
