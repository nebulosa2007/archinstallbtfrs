#!/bin/bash

cd /tmp
wget https://mirror.yandex.ru/archlinux/iso/2022.05.01/archlinux-bootstrap-2022.05.01-x86_64.tar.gz{,.sig}
gpg --keyserver-options auto-key-retrieve --verify archlinux-bootstrap-2022.05.01-x86_64.tar.gz.sig

sudo bash
tar xzf archlinux-bootstrap-*-x86_64.tar.gz --numeric-owner
sed -i 's|#Server = https://mirror.yandex.ru|Server = https://mirror.yandex.ru|' /tmp/root.x86_64/etc/pacman.d/mirrorlist
mount --bind /tmp/root.x86_64/ /tmp/root.x86_64/
/tmp/root.x86_64/bin/arch-chroot /tmp/root.x86_64/
pacman-key --init
pacman-key --populate archlinux
mount /dev/sda1 /mnt
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's|#Server = https://mirror.yandex.ru|Server = https://mirror.yandex.ru|' /etc/pacman.d/mirrorlist
pacman -Syy
pacstrap /mnt base base-devel linux linux-firmware linux-headers grub

