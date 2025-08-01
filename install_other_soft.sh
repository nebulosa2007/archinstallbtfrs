#!/bin/false
# shellcheck shell=bash

## INSTALLING OTHER SOFT

U=nebulosa

#Console useful programs
paru -Syu --needed htop mc ncdu ranger tmux micro lsd
#Optional: paru -S --needed speedread trash bat bpytop


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
cp -r ~/.config/YouTube\ Music/Cache ~/.cache/YouTube\ Music/Cache
rm -fr ~/.config/YouTube\ Music/Cache
ln -s ~/.cache/YouTube\ Music/Cache ~/.config/YouTube\ Music/Cache

cp -r ~/.config/YouTube\ Music/Code\ Cache ~/.cache/YouTube\ Music/Code\ Cache
rm -fr ~/.config/YouTube\ Music/Code\ Cache
ln -s ~/.cache/YouTube\ Music/Code\ Cache ~/.config/YouTube\ Music/Code\ Cache

#Moving .pki in proper place
cp -r ~/.pki ~/.local/share/pki && rm -fr ~/.pki && ln -s ~/.local/share/pki ~/.pki
#Moving .gpg in proper place
cp -r ~/.gnupg ~/.local/share/gnupg && rm -fr ~/.gnupg && ln -s ~/.local/share/gnupg ~/.gnupg

#Switch on discrete card for several applications:
sudo sed -i s'|^Exec=|Exec=env DRI_PRIME=1 |g' /usr/share/applications/firefox.desktop
sudo sed -i s'|^Exec=|Exec=env DRI_PRIME=1 |g' /usr/share/applications/youtube-music.desktop


#Optional old nvidia drivers
paru -S linux-headers nvidia-340xx-dkms
sudo cp /usr/share/nvidia-340xx/20-nvidia.conf /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/Driver "nvidia"/Driver "nvidia"\n  Option "NoLogo" "1"/' /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/ kms / /' /etc/mkinitcpio.conf
sudo mkinitcpio -P
#One TV as only display (for good resolution when TV is on)
##https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#X_with_a_TV_(DFP)_as_the_only_display
#Supress NVRM messages in dmesg
sudo sed -i "s/quiet /quiet video=vesa:off /" /etc/default/grub
sudo sed -i "s/GRUB_GFXPAYLOAD_LINUX=keep/GRUB_GFXPAYLOAD_LINUX=text/" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

#Optional intel drivers
##https://github.com/VDR4Arch/vdr4arch/wiki/VDR4Arch-Installation-(en_US)#intel-va-api
sudo mkdir -p /usr/lib/firmware/edid
sudo cp /sys/class/drm/card1-HDMI-A-3/edid /usr/lib/firmware/edid/edid.bin
sudo sed -i "s/quiet /quiet video=HDMI-A-3:1920x1080@60D drm.edid_firmware=HDMI-A-3:edid/edid.bin/" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo sed -i 's/MODULES=()/MODULES=(i915)/' /etc/mkinitcpio.conf
sudo sed -i 's/FILES=()/FILES=(/usr/lib/firmware/edid/edid.bin)/' /etc/mkinitcpio.conf
sudo mkinitcpio -P
##https://wiki.archlinux.org/title/Intel_graphics#Xorg_configuration
printf "Section \"Device\"\n Identifier \"Intel Graphics\"\n Driver \"modesetting\"\n Option \"DRI\" \"iris\"\n Option \"TearFree\" \"false\"\n Option \"TripleBuffer\" \"false\"\n Option \"SwapbuffersWait\" \"false\"\nEndSection" | sudo tee /etc/X11/xorg.conf.d/20-intel.conf

#DMPS Tuning
printf "Section \"ServerFlags\"\n Option \"IgnoreABI\" \"1\"\n Option \"StandbyTime\" \"0\"\n Option \"SuspendTime\" \"0\"\n Option \"OffTime\" \"0\"\n Option \"BlankTime\" \"0\"\nEndSection" | sudo tee /etc/X11/xorg.conf.d/30-dpms.conf

#Set Locales
##https://wiki.archlinux.org/title/Xorg/Keyboard_configuration#Using_localectl
sudo localectl --no-convert set-x11-keymap us,ru "" "" grp:alt_shift_toggle

#Installing Kodi with autologin lightdm
paru -S kodi lightdm accountsservice
sudo sed -i "s/^\[Seat:\*\]$/\[Seat:\*\]\npam-service=lightdm-autologin\nautologin-user=$U\nautologin-user-timeout=0\nuser-session=kodi/" /etc/lightdm/lightdm.conf

#OR
#Installing Kodi with service
paru -S kodi-standalone-service xorg-server xorg-init
sudo mkdir /etc/systemd/system/kodi-x11.service.d
printf "[Service]\nUser=$U\nGroup=$U\n" | sudo tee -a /etc/systemd/system/kodi-x11.service.d/username.conf
sudo systemctl daemon-reload
sudo systemctl enable kodi-x11.service

#KODI 20.x Fix for nvidia-340xx-dkms and HDMI audio
# echo "LD_PRELOAD=/usr/lib/nvidia/libGL.so.340.108" | sudo tee -a /etc/environment
# echo "KODI_AE_SINK=ALSA" | sudo tee -a /etc/environment
# sudo systemctl --global disable pipewire.socket

#For CEC management
paru -S libcec
sudo usermod -aG uucp,lock $U

#reboot after required
#Youtube tuning -  https://djnapalm.ru/it/kodi/youtube.html
#SponsorsBlock - https://github.com/siku2/script.service.sponsorblock



#Install docker
paru -S docker
#for btrfs snapshots:
#https://forum.garudalinux.org/t/btrfs-docker-and-subvolumes/4601/14
sudo mkdir /etc/docker/ && printf '{\n\t"storage-driver": "overlay2"\t\n}\n' | sudo tee /etc/docker/daemon.json
sudo systemctl enable --now docker.service


#Bonus tuning (russian):
#https://ventureo.codeberg.page

#http://wiki.rosalab.ru/ru/index.php/%D0%9F%D0%B5%D1%80%D0%B5%D0%BD%D0%BE%D1%81_%D1%81%D0%BD%D0%B0%D0%BF%D1%88%D0%BE%D1%82%D0%BE%D0%B2(snapshots)_btrfs_%D0%BD%D0%B0_%D0%B4%D1%80%D1%83%D0%B3%D0%BE%D0%B9_%D1%80%D0%B0%D0%B7%D0%B4%D0%B5%D0%BB_%D0%B2_%D0%BE%D1%82%D0%B4%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D0%BC_%D1%84%D0%B0%D0%B9%D0%BB%D0%B5
