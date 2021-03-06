#!/usr/bin/env bash

## INSTALLATION ARCHLINUX BTRFS ZRAM AND SNAPSHOTS in GRUB method 2
## no separate volume snapshots for Snapper, Timeshift instead with Gnome

#You can use headless machine installation through ssh: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH
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
ip a
ping -c2 1.1.1.1 && ping -c2 nic.ru

#Check needed disks, in my case this is /dev/sda - only one disk
lsblk

#partition disk, in my case BIOS machine: dos, primary, bootable, other space round 10GB - one partition, leave some free space for SSD long live. 
#ex. 232,9GB disk: 230Gb sda1, 2,9GB - free space, ~10%.

#for EFI: gpt, first partition should be efi, 300Mb, ef00 type, all other space - one partition.
#for delete boot table 
#gdisk /dev/sda #x, then z, y, y.
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
btrfs subvolume create @
btrfs subvolume create @home
#btrfs subvolume create @var

#Check if it is everything ok? Should be "@ @home"
ls
#leave directory for successful umount
cd && umount /mnt

#remount subvolumes. Options for SSD
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/sda1 /mnt
mkdir /mnt/home
#Prevent making subvolumes by systemd
#https://bbs.archlinux.org/viewtopic.php?id=260291
mkdir -p /mnt/var/lib/{portables,machines,docker}

mount -o noatime,compress=zstd,space_cache=2,discard=async,subvol=@home /dev/sda1 /mnt/home
#Check 
lsblk

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#NoExtract   =/NoExtract   = usr\/share\/man\/* usr\/share\/help\/* usr\/share\/locale\/* !usr\/share\/locale\/en_GB* !usr\/share\/locale\/locale.alias/' /etc/pacman.conf
#Install archlinux base. Standard linux kernel. For AMD - amd-ucode instead intel-ucode
pacstrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs grub

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

#On a BTRFS ONLY disk (without separate partition fat for EFI) remove fsck HOOK form /etc/mkinitcpio.conf
#and regenerate: sudo mkinitcpio -P linux

#Tune date and time. 'timedatectl list-timezones' for other variants 
hwclock --systohc
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localetime
timedatectl set-ntp true
date

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

#Set network.
pacman -S networkmanager
systemctl enable NetworkManager

#Optional 
pacman -S openssh
systemctl enable sshd

systemctl enable fstrim.timer
pacman -S avahi
systemctl enable avahi-daemon

exit
umount  -R /mnt

#For remove a flashstick
poweroff

#Boot your machine and login as normal user
#Don't forget delete in .ssh/known_hosts line for this host: ssh-keygen -R "[localhost]:2222"

#reflector
sudo pacman -S reflector
sudo reflector --verbose -l 3 -p https --sort rate --save /etc/pacman.d/mirrorlist
sudo systemctl enable reflector.timer

sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

#GNOME because a lot of gtk packages will be install with Timeshift
sudo pacman -S gdm gnome gnome-tweaks gnome-software-packagekit-plugin gnome-extra xorg arc-icon-theme arc-gtk-theme xdg-user-dirs
sudo systemctl enable --now gdm

#pikaur - AUR helper, smallest one
sudo pacman -S --needed git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur

#Install zramd
pikaur zramd
sudo systemctl enable --now zramd

#Install timeshift
#sudo pacman -S --needed git
#git clone https://aur.archlinux.org/timeshift.git
#cd timeshift && makepkg -fsri && cd .. && rm -fr timeshift
#or 
pikaur -S timeshift

#git clone https://aur.archlinux.org/timeshift-autosnap.git
#cd timeshift-autosnap && makepkg -fsri && cd .. && rm -fr timeshift-autosnap
#or
pikaur -S timeshift-autosnap
#Check everything and create first snapshot
sudo timeshift-autosnap

#Install grub-btrfs
sudo pacman -S grub-btrfs
sudo grub-mkconfig -o /boot/grub/grub.cfg

#reboot and take a look on grub menu