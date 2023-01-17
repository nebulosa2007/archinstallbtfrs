#!/usr/bin/env bash

## INSTALLATION ARCHLINUX BTRFS ZRAM

#You can use remote/headless machine installation through ssh: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH
# ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@archiso.lan # (or root@ip_new_arch_install)
#For VirtualBox - Nat forwarding: https://www.virtualbox.org/manual/ch06.html#natforward 
#or in Oracle VM: Settings-Network-Advanced-Port Forwarding: Protocol: TCP, Host Port:2222, Guset IP 10.0.2.15 (check 'ip a' on guest installation), Guest Port:22
#On a host machine: ssh root@localhost -p 2222

#Highly recommended through ssh
#main commands:
# tmux detach
# tmux ls
# tmux attach or tmux attach -t session1 
tmux

#Check internet connection
ip -c a && . <(printf 'ping -c1 "%s" >/dev/null && ' 95.217.163.246 archlinux.org)

#Check needed disks, in my case this is /dev/sda - only one disk
lsblk

#partition disk, in my case BIOS machine: dos, primary, bootable, other space round 10GB - one partition, leave some free space for SSD long live. 
#ex. 232,9GB disk: 230Gb sda1, 2,9GB - free space, ~10%.

#for EFI: gpt, first partition should be efi, 300Mb, ef00 type, all other space - one partition.
#for delete boot table add -z
cfdisk /dev/sda

#for EFI
#mkfs.fat -F32 /dev/sda1
#mkdir /mnt/boot
#mount /dev/sda1 /mnt/boot

#formating one partition in my case, with EFI it will be sda2
#you may add -f: force format, -L virtarch - for label 
mkfs.btrfs /dev/sda1

#making btrfs subvolumes
mount /dev/sda1 /mnt
cd /mnt
btrfs subvolume create @root
btrfs subvolume create @home

#Check if it is everything ok? Should be "@ @home"
ls
#leave directory for successful umount
cd && umount /mnt

#remount subvolumes. Options for SSD
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@root /dev/sda1 /mnt
mkdir /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/sda1 /mnt/home
#Prevent making subvolumes by systemd
#https://bbs.archlinux.org/viewtopic.php?id=260291
mkdir -p /mnt/var/lib/{portables,machines,docker}

#Check 
lsblk

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#NoExtract   =/NoExtract   = usr\/share\/man\/* usr\/share\/help\/* usr\/share\/locale\/* !usr\/share\/locale\/en_US* !usr\/share\/locale\/locale.alias/' /etc/pacman.conf
#Install archlinux base. Standard linux kernel. For AMD - amd-ucode instead intel-ucode
pacstrap -K /mnt base linux intel-ucode btrfs-progs grub polkit micro sudo reflector 

#For wi-fi
#pacstrap /mnt iwd linux-firmware

cp -i /etc/pacman.conf /mnt/etc/pacman.conf

#generate fstab
genfstab -U /mnt >> /mnt/etc/fstab


#start the party!
arch-chroot /mnt


##INSIDE CHROOT

#set variables
M=virtarch
U=nebulosa

#Double check fstab!
cat /etc/fstab

#Time tuning
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && hwclock --systohc

#Uncomment en_GB.UTF-8 only and generate locales
sed -i 's/#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen && locale-gen
#Set locales for other GUI programs
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf

#Set machine name. "virtarch" in my case.
echo $M >> /etc/hostname
printf "127.0.0.1 localhost\n::1       localhost\n127.0.0.1 $M.localhost $M\n" >> /etc/hosts
cat /etc/hostname /etc/hosts

#Set root password. CHANGE FOR YOUR OWN
echo root:password | chpasswd

#install GRUB on BIOS
grub-install --target=i386-pc --recheck /dev/sda
#for EFI:
#pacman -S efibootmgr
#grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

#Optional
#echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
#sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#Add user login in system
useradd -mG wheel $U
passwd $U
#Sudo activating
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

#Set network (DHCP, systemd-networkd)
#Wired
printf "[Match]\nName=en*\n\n[Network]\nDHCP=yes\n" > /etc/systemd/network/20-wired.network

#Wireless
# printf "[Match]\nName=wl*\n\n[Network]\nDHCP=yes\nIgnoreCarrierLoss=3s\n" > /etc/systemd/network/25-wireless.network
# systemctl enable iwd

systemctl enable systemd-networkd

#Zram
echo "zram" > /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
echo 'KERNEL=="zram0", ATTR{disksize}="'$(awk '/MemTotal/ {print $2}' /proc/meminfo)'K" RUN="/usr/bin/mkswap /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
echo "/dev/zram0     none     swap     defaults     0     0" >> /etc/fstab

#Other
systemctl enable reflector.timer
systemctl enable fstrim.timer

pacman -S openssh avahi
systemctl enable sshd
systemctl enable avahi-daemon

exit
umount  -R /mnt

#For remove a flashstick
poweroff


#Boot your machine and login as normal user
#Don't forget delete in .ssh/known_hosts line for this host: ssh-keygen -R "[localhost]:2222"

#Instead of sudo systemctl enable --mow systemd-resolved.service
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo systemctl restart systemd-networkd
#Wi-fi connection - https://wiki.archlinux.org/title/Iwd#Connect_to_a_network

#On a BTRFS ONLY disk (without separate partition fat for EFI) remove fsck HOOK form /etc/mkinitcpio.conf
#for default preset only
# sudo sed -i "s/PRESETS=('default' 'fallback')/PRESETS=('default')/" /etc/mkinitcpio.d/linux.preset
# sudo rm /boot/initramfs-linux-fallback.img
#Optional, set the console keyboard layout
# printf "FONT=cyr-sun16\nKEYMAP=ru\n" | sudo tee /etc/vconsole.conf
sudo mkinitcpio -P

#NTP turn on
sudo timedatectl set-ntp true
sudo timedatectl status

#pikaur - AUR helper, smallest one
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur

#Optional: make initial snapshot
# sudo mount /dev/sda1 /mnt && sudo btrfs subvolume snapshot /mnt/@root /mnt/INIT && sudo umount /mnt
