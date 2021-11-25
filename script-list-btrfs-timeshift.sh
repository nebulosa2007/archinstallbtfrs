#!/usr/bin/env bash

## INSTALLATION ARCHLINUX BTRFS ZRAM AND SNAPSHOTS in GRUB method 2
## no separate volume snapshots for Snapper, Timeshift instead with Gnome

#You can use headless machine installation through ssh: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH
#For VirtualBox - Nat forwarding: https://www.virtualbox.org/manual/ch06.html#natforward 
#or in Oracle VM: Settings-Network-Advanced-Port Forwarding: Protocol: TCP, Host Port:2222, Guset IP 10.0.2.15 (check 'ip a' on guest installation), Guest Port:22
#On a host machine: ssh root@localhost -p 2222

$MACHINE_NAME="virtarch"
$MAIN_USER="nebulosa"

#Check internet connection
ip a
ping -c2 1.1.1.1

#Check needed disks, in my case this is /dev/sda - only one disk
lsblk

#partition disk, in my case BIOS machine: dos, primary, bootable, all space - one partition.
#for EFI: gpt, first partition should be efi, 300Mb, ef00 type, all other space - one partition.
cfdisk /dev/sda

#for EFI
#mkfs.fat -F32 /dev/sda1
#mkdir /mnt/boot
#mount /dev/sda1 /mnt/boot

#formating one partition in my case, with EFI it will be sda2
mkfs.btrfs /dev/sda1

#making btrfs subvolumes
mount /dev/sda1 /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
#btrfs subvolume create @var

#Check if it is everything ok? Should be "@ @home @var"
ls
#leave directory for successful umount
cd
umount /mnt

#remount subvolumes. Options for SSD
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/sda1 /mnt
#mkdir -p /mnt/{home,var}
mkdir /mnt/home
mount -o noatime,compress=zstd,space_cache=2,discard=async,subvol=@home /dev/sda1 /mnt/home
#mount -o noatime,compress=zstd,space_cache=2,discard=async,subvol=@var /dev/sda1 /mnt/var

#Check 
lsblk

#Install archlinux base. Standard linux kernel. For AMD - amd-ucode instead intel-ucode
pacstrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs grub

#generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#start the party!
arch-chroot /mnt


##INSIDE CHROOT

#Double check fstab!
cat /etc/fstab

#On a BTRFS ONLY disk (without separate partition fat for EFI) remove fsck HOOK form /etc/mkinitcpio.conf
#and regenerate: sudo mkinitcpio -P linux

#Tune date and time. 'timedatectl list-timezones' for other variants 
hwclock --systohc
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localetime
timedatectl set-ntp true
date

#Uncomment en_US.UTF-8 only and generate locales
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
#Set locales for other GUI programs
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

#Set machine name. "virtarch" in my case.
echo "$MACHINE_NAME" >> /etc/hostname
printf "127.0.0.1 localhost\n::1       localhost\n127.0.0.1 $MACHINE_NAME.localhost $MACHINE_NAME" >> /etc/hosts

#Set root password. CHANGE FOR YOUR OWN
echo root:password | chpasswd

#install GRUB on BIOS
grub-install --target=i386-pc --recheck /dev/sda
#for EFI:
#pacman -S efibootmgr
#grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#Add user login in system
useradd -mG wheel $MAIN_USER
passwd $MAIN_USER
#Sudo activating
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheelgroup

#Set network.
pacman -S networkmanager
systemctl enable NetworkManager

#Optional 
pacman -S openssh
systemctl enable sshd

#Install and tune zram 2GB
pacman -S zram-generator
printf "[zram0]\ncompression-algorithm = zstd\nzram-fraction = 1\nmax-zram-size = 2048" >> /etc/systemd/zram-generator.conf


exit
#target id busy is normal
umount -a

#For remove a flashstick
poweroff

#Boot your machine and login as normal user
#Don't forget delete in .ssh/known_hosts line for this host: ssh-keygen -R "[localhost]:2222"

#reflector
sudo pacman -S reflector
sudo reflector --verbose -l 3 -p https --sort rate --save /etc/pacman.d/mirrorlist
sudo systemctl enable reflector.timer

#GNOME because a lot of gtk packages will be install with Timeshift
sudo pacman -S gdm gnome gnome-tweaks gnome-software-packagekit-plugin gnome-extra xorg 
sudo systemctl enable --now gdm

#pikaur - AUR helper, smallest one
#sudo pacman -S --needed git
#git clone https://aur.archlinux.org/pikaur.git
#cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur

#Install timeshift and timeshift-autosnap
sudo pacman -S --needed git
git clone https://aur.archlinux.org/timeshift.git
cd timeshift && makepkg -fsri && cd .. && rm -fr timeshift

git clone https://aur.archlinux.org/timeshift-autosnap.git
cd timeshift-autosnap && makepkg -fsri && cd .. && rm -fr timeshift-autosnap

#Install grub-btrfs
sudo pacman -S grub-btrfs
sudo grub-mkconfig -o /boot/grub/grub.cfg
#Add hooks for boot in read only. Works with separate @var only
#sudo nano /etc/mkinitcpio.conf
#HOOKS=( ... grub-btrfs-overlayfs)
#sudo mkinitcpio -P

#Check everything and create first snapshot
sudo timeshift-autosnap

#reboot and take a look on grub menu.


## INSTALLING OTHER SOFT

#Upgrade system
sudo pacman -Syu

#console helpers
sudo pikaur -S htop mc ncdu inxi micro


#Bonus tuning (russian):
#https://docs.google.com/document/d/1IjTxl7LaPKJyRoLpGEhm4ptBhob_jRgLLQpMugS7qe8/edit

#to be continued...