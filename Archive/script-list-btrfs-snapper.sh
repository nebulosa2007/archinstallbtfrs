#!/usr/bin/env bash

## INSTALLATION ARCHLINUX BTRFS ZRAM AND SNAPSHOTS ITEMS in GRUB

#You can use headless machine installation through ssh: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH
#For VirtualBox - Nat forwarding: https://www.virtualbox.org/manual/ch06.html#natforward 
#or in Oracle VM: Settings-Network-Advanced-Port Forwarding: Protocol: TCP, Host Port:2222, Guset IP 10.0.2.15 (check 'ip a' on guest installation), Guest Port:22
#On a host machine: ssh root@localhost -p 2222

$MACHINE_NAME="virtarch"
$MAIN_USER="nebulosa"

#Check internet connection
ip a
ping -c3 1.1.1.1

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
btrfs subvolume create @snapshots
btrfs subvolume create @var

#Check if it is everything ok? Should be "@ @home @snapshots @var-log"
ls
#leave directory for successful umount
cd
umount /mnt

#remount subvolumes. Options for SSD
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/sda1 /mnt
mkdir -p /mnt/{home,.snapshots,var}
mount -o noatime,compress=zstd,space_cache=2,discard=async,subvol=@home /dev/sda1 /mnt/home
mount -o noatime,compress=zstd,space_cache=2,discard=async,subvol=@snapshots /dev/sda1 /mnt/.snapshots
mount -o noatime,compress=zstd,space_cache=2,discard=async,subvol=@var /dev/sda1 /mnt/var

#Check 
lsblk

#Install archlinux base. Standard linux kernel. For AMD - amd-ucode instead intel-ucode
pacstrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs grub nano

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
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localetime
hwclock --systohc
timedatectl set-ntp true

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
#Sudo
echo "$MAIN_USER ALL=(ALL) ALL" >> /etc/sudoers.d/$MAIN_USER

#Set network.
pacman -S networkmanager
systemctl enable NetworkManager

#Optional. 
pacman -S openssh
systemctl enable sshd

#Install and tune zram 2GB
pacman -S zram-generator
printf "[zram0]\ncompression-algorithm = zstd\nzram-fraction = 0.5\nmax-zram-size = 2048" >> /etc/systemd/zram-generator.conf

exit
#target id busy is normal
umount -a

#For removing flashstick
poweroff

#Boot your machine and login as normal user
#Don't forget delete in .ssh/known_hosts line for this host: ssh-keygen -R "[localhost]:2222"

#Install and tune snapper #https://youtu.be/Xynotc9BKe8?t=1682 
#https://wiki.archlinux.org/title/Snapper#Configuration_of_snapper_and_mount_point
sudo pacman -S snapper
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
sudo chmod a+rx /.snapshots
sudo chown :$MAIN_USER /.snapshots
sudo nano /etc/snapper/configs/root
#ALLOW_USERS="write you login"
#...#limits for timeline cleanup
#...HOURLY=5, DAILY=7, other LIMIT = 0 use wiki for details
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

#for EFI
#sudo pacman -S rsync
#sudo mkdir /etc/pacman.d/hooks
#sudo nano /etc/pacman.d/hooks/50-bootbackup.hook
#[Trigger]
#Operation  = Upgrade
#Operation = Install
#Operation = Remove
#Type = Path
#Target = boot/*
#
#[Action]
#Depends = rsync
#Description = Backup up /boot...
#When = PreTransaction
#Exec = /usr/bin/rsync -a --delete /boot /.bootbackup

#pikaur - AUR helper, smallest one
sudo pacman -S --needed git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur

#For generation items in grub
pikaur -S snap-pac-grub

#Reboot and take a look on grub menu.

#Scriptlist booting from writable snapshot in emergency
#https://youtu.be/sm_fuBeaOqE?t=2002 - revert snapshot from arch iso
#to boot in writable snapshot
#https://youtu.be/sm_fuBeaOqE?t=2278
#list snapshots, choose one of them, for example 24 
#snapper -c root list
#Check ro 
#btrfs property list -ts /.snapshots/24/snapshot/
#make it writable
#sudo btrfs property set -ts /.snapshots/24/snapshot/ ro false
#reboot and choose in grub 24th snapshot


## INSTALLING OTHER SOFT

#Upgrade system
sudo pacman -Syu

#console helpers
sudo pikaur -S htop mc ncdu inxi micro

#Bonus tuning:
https://docs.google.com/document/d/1IjTxl7LaPKJyRoLpGEhm4ptBhob_jRgLLQpMugS7qe8/edit