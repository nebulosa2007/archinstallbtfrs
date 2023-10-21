#!/usr/bin/env bash

## INSTALLATION ARCHLINUX BTRFS ZRAM

#You can use remote/headless machine installation through ssh: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH
# ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@archiso.lan # (or root@ip_new_arch_install)
#For VirtualBox - Nat forwarding: https://www.virtualbox.org/manual/ch06.html#natforward 
#or in Oracle VM: Settings-Network-Advanced-Port Forwarding: Protocol: TCP, Host Port:2222, Guset IP 10.0.2.15 (check 'ip a' on guest installation), Guest Port:22
#On a host machine: ssh root@localhost -p 2222

#For DCHP ONLY!
#printf "[Match]\nName=en*\nName=eth*\n\n[Network]\nDHCP=yes\n" > /etc/systemd/network/20-ethernet.network
# or
## /etc/systemd/network/20-ethernet.network
## Name=en*
## Name=eth*
## 
## [Network]
## Gateway=......
## Address=....../24  - IPv4
##
## Gateway=......
## Address=....../48  - IPv6

echo "nameserver 9.9.9.9" > /etc/resolv.conf
systemctl restart systemd-networkd
ip -c a
passwd
exit


# Connect through ssh: root@ip
ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@ip_server

#Highly recommended through ssh
#main commands:
# tmux detach
# tmux ls
# tmux attach or tmux attach -t session1 
tmux


#Check needed disks, in my case this is /dev/sda - only one disk
lsblk

#Main partition:
MPART="/dev/sda" # or "/dev/vda" on case of VPS

#partition disk, BIOS machine, KVM VPS: dos, primary, bootable
#other space round 10GB - one partition, leave some free space for SSD long live. 
#ex. 232,9GB disk: 230Gb sda1, 2,9GB - free space, ~10%.
#or all space for 1 Partition for VPS.

#for EFI: gpt, first partition should be efi, 300Mb, ef00 type, all other space - one partition.
#for delete boot table add -z
cfdisk $MPART

#for EFI
# mkfs.fat -F32 /dev/sda1
# mkdir /mnt/boot
# mount /dev/sda1 /mnt/boot

#formating one partition in my case, with EFI it will be sda2 or vda2
#you may add -f: force format, -L virtarch - for label 
mkfs.btrfs $MPART"1"

#making btrfs subvolumes
mount $MPART"1" /mnt
cd /mnt
btrfs subvolume create @root
btrfs subvolume create @home

#Check if it is everything ok? Should be "@root @home"
ls
#leave directory for unmount
cd && umount /mnt

#remount subvolumes. Options for SSD
mount -o relatime,ssd_spread,compress=zstd,space_cache=v2,max_inline=256,discard=async,subvol=@root $MPART"1" /mnt
mkdir /mnt/home
mount -o relatime,ssd_spread,compress=zstd,space_cache=v2,max_inline=256,discard=async,subvol=@home $MPART"1" /mnt/home
#Prevent making subvolumes by systemd
#https://bbs.archlinux.org/viewtopic.php?id=260291
mkdir -p /mnt/var/lib/{portables,machines,docker}

#Check mountpoints
lsblk

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#NoExtract   =/NoExtract   = usr\/share\/man\/* usr\/share\/help\/* usr\/share\/locale\/* !usr\/share\/locale\/en_GB* !usr\/share\/locale\/locale.alias/' /etc/pacman.conf
#Install archlinux base. Standard linux kernel.
pacstrap -K /mnt base linux grub btrfs-progs sudo # minimum - VPS
# For AMD - amd-ucode instead intel-ucode
pacstrap /mnt intel-ucode micro reflector # + other soft - desktop

#For wi-fi
#pacstrap /mnt iwd linux-firmware

#If static network ip
#cp -i /etc/systemd/network/20-ethernet.network /mnt/etc/systemd/network/20-ethernet.network

cp -i /etc/pacman.conf /mnt/etc/pacman.conf

#generating fstab
genfstab -U /mnt >> /mnt/etc/fstab


#start the party!
arch-chroot /mnt


##INSIDE CHROOT

#set variables
M=virtarch
U=nebulosa
MPART="/dev/sda"

#Double check fstab!
cat /etc/fstab

#Time tuning
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && hwclock --systohc

#On a BTRFS ONLY disk (without separate partition fat for EFI) remove fsck HOOK form /etc/mkinitcpio.conf
#for default preset only
# sed -i "s/PRESETS=('default' 'fallback')/PRESETS=('default')/" /etc/mkinitcpio.d/linux.preset
# mkinitcpio -P
# rm /boot/initramfs-linux-fallback.img

#Uncomment en_GB.UTF-8 only and generate locales
sed -i 's/#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen && locale-gen
#Set locales for other GUI programs
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

#Set machine name. "virtarch" in my case.
echo $M >> /etc/hostname
printf "127.0.0.1 localhost\n::1       localhost\n127.0.0.1 $M.localhost $M\n" >> /etc/hosts
cat /etc/hostname /etc/hosts

#Set root "password". Or use passwd command. CHANGE FOR YOUR OWN
#echo root:password | chpasswd

#install GRUB on BIOS
grub-install --target=i386-pc --recheck $MPART
#for EFI:
# pacman -S efibootmgr
# grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

#Optional
# sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
# sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
# sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rootfstype=btrfs raid=noautodetect mitigations=off preempt=none audit=0 page_alloc.shuffle=1 split_lock_detect=off pci=pcie_bus_perf"/' /etc/default/grub
# sed -i "s/rootfstype=btrfs /rootfstype=btrfs lpj=$(dmesg | grep -Po '(?<=lpj=)(\d+)') /" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#Add user login in system
useradd -mG wheel,storage $U
passwd $U
#Sudo activating
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

#Set network (DHCP, systemd-networkd)
mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
printf "[Service]\nExecStart=\nExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any\n" > /etc/systemd/system/systemd-networkd-wait-online.service.d/wait-for-only-one-interface.conf

#Wired DCHP
# printf "[Match]\nName=en*\n\n[Network]\nDHCP=yes\n" > /etc/systemd/network/20-wired.network

#Wireless
# printf "[Match]\nName=wl*\n\n[Network]\nDHCP=yes\nIgnoreCarrierLoss=3s\n" > /etc/systemd/network/25-wireless.network
# systemctl enable iwd
systemctl enable systemd-networkd

#Zram
pacman -S zram-generator
printf "[zram0]\nzram-size = ram\ncompression-algorithm = zstd\n" > /etc/systemd/zram-generator.conf

#Other
# systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable systemd-homed

#VPS
# pacman -S vnstat
# systemctl enable vnstat

# Desktop
pacman -S avahi
systemctl enable avahi-daemon

pacman -S openssh
systemctl enable sshd

exit
umount  -R /mnt

#For remove a flashstick
poweroff


#Boot your machine and login as normal user
#Don't forget delete in .ssh/known_hosts line for this host: ssh-keygen -R "[localhost]:2222"

#Add your key in SSH server:
ssh-copy-id -i $HOME/.ssh/id_ed25519.pub user@ip_server

#Instead of sudo systemctl enable --mow systemd-resolved.service
echo -e "nameserver 9.9.9.9\noptions timeout:3 attempts:3" | sudo tee /etc/resolv.conf

#If server has domain name 
# DOMAIN="mydomain.com"
# echo "search $DOMAIN" | sudo tee -a /etc/resolv.conf
# echo "127.0.0.1 $DOMAIN.localhost $DOMAIN" | sudo tee -a /etc/hosts

sudo systemctl restart systemd-networkd
#Wi-fi connection - https://wiki.archlinux.org/title/Iwd#Connect_to_a_network

#Check internet connection and DNS resolution - no error is ok
ip -c a && (eval $(printf 'ping -c1 "%s" >/dev/null & ' 95.217.163.246 archlinux.org) && wait;)

#Optional, set the console keyboard layout
# printf "FONT=cyr-sun16\nKEYMAP=ru\n" | sudo tee /etc/vconsole.conf
# https://bbs.archlinux.org/viewtopic.php?pid=2095416#p2095416
# sed -i 's/BINARIES=()/BINARIES=(setfont)/' /etc/mkinitcpio.conf
# sudo mkinitcpio -P

#NTP turn on
sudo timedatectl set-ntp true && timedatectl status

#pikaur - AUR helper, smallest one
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur

#Optional: watchdog off
# echo -e "blacklist $(wdctl | grep -E -o "iTCO[^ ]+")" | sudo tee -a /etc/modprobe.d/blacklist.conf
#Supress TSC messages in dmesg
# sudo sed -i "s/quiet /quiet trace_clock=global nowatchdog /" /etc/default/grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg

#Optional: wireless, respecting the regulatory domain
# sudo pacman -S wireless-regdb
# sudo sed -i 's/#WIRELESS_REGDOM="RU"/WIRELESS_REGDOM="RU"/' /etc/conf.d/wireless-regdom

#Optional: make initial snapshot
# sudo pacman -Scc && sudo pacman -Rsn $(pacman -Qdtq)
# sudo journalctl --vacuum-size=5M && sudo journalctl --verify
# sudo mount /dev/sda1 /mnt && sudo btrfs subvolume snapshot /mnt/@root /mnt/INIT && sudo umount /mnt

#Optional: https://ventureo.codeberg.page/source/extra-optimizations.html#alhp-repository
