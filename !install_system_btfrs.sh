## INSTALLATION ARCHLINUX BTRFS with ZRAM and snapshots

## https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH
#You can use remote/headless machine installation through ssh
# ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@archiso.lan # (or root@ip_new_arch_install)
#For VirtualBox - Nat forwarding: https://www.virtualbox.org/manual/ch06.html#natforward 
#or in Oracle VM: Settings-Network-Advanced-Port Forwarding: Protocol: TCP, Host Port:2222, Guset IP 10.0.2.15 (check 'ip a' on guest installation), Guest Port:22
#On a host machine: ssh root@localhost -p 2222

## https://wiki.archlinux.org/title/Systemd-networkd#Wired_adapter_using_DHCP
#For DCHP ONLY!
#printf "[Match]\nName=en*\nName=eth*\n\n[Network]\nDHCP=yes\n" > /etc/systemd/network/20-ethernet.network
# or
## https://wiki.archlinux.org/title/Systemd-networkd#Wired_adapter_using_a_static_IP
## IPv6 static: https://wiki.archlinux.org/title/IPv6#systemd-networkd_3
## /etc/systemd/network/20-ethernet.network
## [Match]
## Name=en*
## Name=eth*
## 
## [Network]
## Gateway=......
## Address=....../24  - IPv4
##
## Gateway=......
## Address=....../48  - IPv6
## LinkLocalAddressing=no
## IPv6AcceptRA=false

## https://wiki.archlinux.org/title/Domain_name_resolution#Glibc_resolver
echo "nameserver 9.9.9.9" > /etc/resolv.conf
systemctl restart systemd-networkd

## https://wiki.archlinux.org/title/Network_configuration#IP_addresses
ip -c a
passwd
exit

## https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH#On_the_local_machine
# Connect through ssh: root@ip
ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@ip_server

## https://wiki.archlinux.org/title/Tmux
#Highly recommended through ssh
#main commands are:
# tmux detach
# tmux ls
# tmux attach or tmux attach -t session1 
tmux


#Check needed disks
lsblk

#Main partition:
MPART="/dev/sda" # or "/dev/vda" on case of VPS

## https://wiki.archlinux.org/title/GRUB
#All space for 1 Partition for VPS. KVM virtualisation uses BIOS setup,
#so set dos, primary, bootable for partition
#For Desktop
#Leave some free space for SSD long live. See "SSD overprovisioning" for more info
#ex. 232,9GB round partition to 230Gb. 2,9GB - will be free space, ~10%
#BIOS: one partition
#EFI: gpt, first partition should be efi, 16Mb, ef00 type, all other space - one partition.

## https://wiki.archlinux.org/title/Fdisk - cfidsk - a curses-based user interface
#for delete boot table add -z
cfdisk -z $MPART

#for EFI
# mkfs.fat -F32 /dev/sda1
# mount -m /dev/sda1 /mnt/boot/efi

## https://wiki.archlinux.org/title/Btrfs#File_system_creation
#formating one partition in my case, with EFI it will be sda2 or vda2
#you may add -f: force format, -L virtarch - for label 
mkfs.btrfs $MPART"1"

#making btrfs subvolumes due to https://github.com/hirak99/yabsnap#recommended-subvolume-layout
mount $MPART"1" /mnt
cd /mnt
## https://wiki.archlinux.org/title/Btrfs#Creating_a_subvolume
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @swap

#Check if it is everything ok? Should be "@ @home @snapshots @swap"
ls
#leave directory for unmount
cd && umount /mnt

#Remount subvolumes. Options for SSD
## https://ventureo.codeberg.page/source/file-systems.html#btrfs
mount -o ssd_spread,compress=zstd:3,max_inline=256,subvol=@ $MPART"1" /mnt
mkdir /mnt/{home,.snapshots,.swap}
mount -o ssd_spread,compress=zstd:3,max_inline=256,subvol=@home $MPART"1" /mnt/home
mount -o ssd_spread,compress=zstd:3,max_inline=256,subvol=@snapshots $MPART"1" /mnt/.snapshots
mount -o ssd_spread,compress=zstd:3,max_inline=256,subvol=@swap $MPART"1" /mnt/.swap

## https://bbs.archlinux.org/viewtopic.php?id=260291
#Prevent making subvolumes by systemd
mkdir -p /mnt/var/lib/{portables,machines,docker}

#Check mountpoints
lsblk

## https://wiki.archlinux.org/title/Pacman#Enabling_parallel_downloads
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

## https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Installing_only_content_in_required_languages
#Skip installing man and help pages, other locales for all packages in system
TODO: one line adding
NoExtract = usr/share/help/* !usr/share/help/C/*
NoExtract = usr/share/gtk-doc/html/*
NoExtract = usr/share/locale/* usr/share/X11/locale/*/* usr/share/i18n/locales/* opt/google/chrome/locales/* !usr/share/X11/locale/C/*
NoExtract = !usr/share/X11/locale/compose.dir !usr/share/X11/locale/iso8859-1/*
NoExtract = !*locale*/en*/* !usr/share/*locale*/locale.*
NoExtract = !usr/share/*locales/en_?? !usr/share/*locales/i18n* !usr/share/*locales/iso*
NoExtract = usr/share/i18n/charmaps/* !usr/share/i18n/charmaps/UTF-8.gz !usr/share/i18n/charmaps/ANSI_X3.4-1968.gz
NoExtract = !usr/share/*locales/trans*
NoExtract = !usr/share/*locales/C !usr/share/*locales/POSIX
NoExtract = usr/share/man/* !usr/share/man/man*
NoExtract = usr/share/*/translations/*.qm usr/share/*/nls/*.qm usr/share/qt/phrasebooks/*.qph usr/share/qt/translations/*.pak !*/en-GB.pak
NoExtract = usr/share/*/locales/*.pak opt/*/locales/*.pak usr/lib/*/locales/*.pak !*/en-GB.pak
NoExtract = usr/lib/libreoffice/help/*

## https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages
#Install archlinux base. Standard linux kernel.
pacstrap -K /mnt base linux grub btrfs-progs sudo openssh micro # minimum - VPS

##https://wiki.archlinux.org/title/Microcode
#If VPS and other virtualisations skip this step!
#For AMD - amd-ucode
#pacstrap /mnt amd-ucode
#For Intel - intel-ucode
#pacstrap /mnt intel-ucode

## https://wiki.archlinux.org/title/Iwd
#For wi-fi
#pacstrap /mnt iwd linux-firmware

#If static network ip
#cp -i /etc/systemd/network/20-ethernet.network /mnt/etc/systemd/network/20-ethernet.network

cp -i /etc/pacman.conf /mnt/etc/pacman.conf

##https://wiki.archlinux.org/title/Installation_guide#Configure_the_system
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && hwclock --systohc #Use your own region
# fix for line 115...
touch /usr/share/locale/locale.alias
sed -i 's/#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen && locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

M=arch
echo $M >> /etc/hostname
printf "127.0.0.1 localhost\n::1       localhost\n127.0.0.1 $M.localhost $M\n" >> /etc/hosts

## https://wiki.archlinux.org/title/Mkinitcpio/Minimal_initramfs
#On a BTRFS ONLY disk (without separate partition fat for EFI) remove fsck HOOK form /etc/mkinitcpio.conf
# sed -i "s/PRESETS=('default' 'fallback')/PRESETS=('default')/" /etc/mkinitcpio.d/linux.preset
# sed -i "s|ALL_microcode=(/boot/*-ucode.img)|#ALL_microcode=(/boot/*-ucode.img)|" /etc/mkinitcpio.d/linux.preset
# mkinitcpio -P
# rm /boot/initramfs-linux-fallback.img

passwd #For root

## https://wiki.archlinux.org/title/GRUB#Installation_2
#install GRUB on BIOS
grub-install --recheck /dev/sda #Or /dev/vda for VPS
## https://wiki.archlinux.org/title/GRUB#Installation
#for EFI:
# pacman -S efibootmgr
# grub-install
#Optional
## https://wiki.archlinux.org/title/GRUB#Configuration
# sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
# sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
## https://ventureo.codeberg.page/source/kernel-parameters.html
# sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rootfstype=btrfs raid=noautodetect mitigations=off preempt=none audit=0 page_alloc.shuffle=1 split_lock_detect=off pci=pcie_bus_perf"/' /etc/default/grub
# sed -i "s/rootfstype=btrfs /rootfstype=btrfs lpj=$(dmesg | grep -Po '(?<=BogoMIPS \(lpj=)(\d+)') /" /etc/default/grub
# echo "GRUB_EARLY_INITRD_LINUX_STOCK=''" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

#Double check files!
cat /etc/fstab /etc/hostname /etc/hosts

## https://wiki.archlinux.org/title/Users_and_groups#User_management
U=nebulosa
useradd -mG wheel,storage $U
passwd $U

## https://wiki.archlinux.org/title/Sudo#Example_entries
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

## https://wiki.archlinux.org/title/Systemd-networkd#systemd-networkd-wait-online
mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
printf "[Service]\nExecStart=\nExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any\n" > /etc/systemd/system/systemd-networkd-wait-online.service.d/wait-for-only-one-interface.conf

#Wired DCHP
# printf "[Match]\nName=en*\n\n[Network]\nDHCP=yes\n" > /etc/systemd/network/20-wired.network

#Wireless
## https://wiki.archlinux.org/title/Iwd#Connect_to_a_network
# printf "[Match]\nName=wl*\n\n[Network]\nDHCP=yes\nIgnoreCarrierLoss=3s\n" > /etc/systemd/network/25-wireless.network
# systemctl enable iwd
systemctl enable systemd-networkd

#Zram https://wiki.archlinux.org/title/Zram#Using_zram-generator
sed -i "s/quiet/quiet zswap.enabled=0 /;s/  / /" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S zram-generator
printf "[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\nswap-priority = 100\nfs-type = swap\n" > /etc/systemd/zram-generator.conf

#Other
## https://wiki.archlinux.org/title/Reflector#systemd_timer
# systemctl enable reflector.timer
## https://wiki.archlinux.org/title/Solid_state_drive#Periodic_TRIM
systemctl enable fstrim.timer
## https://wiki.archlinux.org/title/Systemd-homed
systemctl enable systemd-homed
## https://wiki.archlinux.org/title/OpenSSH#Daemon_management
systemctl enable sshd

#For VPS
## https://wiki.archlinux.org/title/VnStat
# pacman -S vnstat
# systemctl enable vnstat

# Desktop
##https://wiki.archlinux.org/title/Avahi
pacman -S avahi
systemctl enable avahi-daemon

exit
umount -R /mnt

#For remove a flashstick
poweroff


#Boot your machine and login as normal user
#Don't forget delete in .ssh/known_hosts line for this host: ssh-keygen -R "[localhost]:2222"

## https://wiki.archlinux.org/title/SSH_keys#Simple_method
ssh-copy-id -i $HOME/.ssh/id_ed25519.pub user@ip_server

#If server has domain name
# DOMAIN="mydomain.com"
# echo "search $DOMAIN" | sudo tee -a /etc/resolv.conf
# echo "127.0.0.1 $DOMAIN.localhost $DOMAIN" | sudo tee -a /etc/hosts

## https://wiki.archlinux.org/title/Systemd-resolved
sudo systemctl enable --now systemd-resolved.service
sudo systemctl restart systemd-networkd

#Check internet connection and DNS resolution - no error is ok
ip -c a && (eval $(printf 'ping -c1 "%s" >/dev/null & ' 95.217.163.246 archlinux.org) && wait;)

#Optional
## https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration
# printf "FONT=cyr-sun16\nKEYMAP=ru\n" | sudo tee /etc/vconsole.conf
## https://bbs.archlinux.org/viewtopic.php?pid=2095416#p2095416
# sed -i 's/BINARIES=()/BINARIES=(setfont)/' /etc/mkinitcpio.conf
# sudo mkinitcpio -P

## https://wiki.archlinux.org/title/Systemd-timesyncd#Usage
sudo timedatectl set-ntp true && sleep 3 && timedatectl status

## https://github.com/actionless/pikaur
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur && makepkg -fsri && cd .. && rm -rf pikaur

## https://wiki.archlinux.org/title/Improving_performance#Watchdogs
#Optional: watchdog off on Desktop systems
# echo -e "blacklist $(wdctl | grep -E -o "iTCO[^ ]+")" | sudo tee -a /etc/modprobe.d/blacklist.conf
#Supress TSC messages in dmesg
# sudo sed -i "s/quiet /quiet trace_clock=global nowatchdog /" /etc/default/grub
# sudo grub-mkconfig -o /boot/grub/grub.cfg

## https://wiki.archlinux.org/title/Network_configuration/Wireless#Respecting_the_regulatory_domain
#Optional:
# sudo pacman -S wireless-regdb
# sudo sed -i 's/#WIRELESS_REGDOM="RU"/WIRELESS_REGDOM="RU"/' /etc/conf.d/wireless-regdom

## https://wiki.archlinux.org/title/Pkgstats
#Optional:
# sudo pacman -S pkgstats
# sudo systemctl start pkgstats.timer
# pkgstats submit

## https://wiki.archlinux.org/title/Btrfs#Swap_file
#Optional:
# sudo btrfs filesystem mkswapfile --size 4g --uuid clear /.swap/swapfile
# swapon /.swap/swapfile
# echo  "/.swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab

#Todo https://wiki.archlinux.org/title/Btrfs#Booting_into_snapshots grub-btrfs
#Optional: https://ventureo.codeberg.page/source/extra-optimizations.html#alhp-repository
