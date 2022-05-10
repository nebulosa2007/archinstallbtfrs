#!/bin/bash

df -h | egrep  "[s|v]da"
sudo apt-get purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | head -n -1)

sudo apt-get autoclean
sudo apt-get clean
sudo apt-get autoremove --purge
sudo localepurge


dpkg -l | awk '/^rc/ {print $2}' | xargs sudo dpkg --purge

sudo journalctl --disk-usage
sudo journalctl --vacuum-size=5M
sudo journalctl --verify
sudo journalctl --disk-usage

find /var/log -type f -regex ".*\.gz$" 2> /dev/null | sudo xargs rm -rf
find /var/log -type f -regex ".*\.[0-9]$" 2> /dev/null| sudo xargs rm -rf

#find /usr/share/doc -depth -type f | sudo xargs rm -rf
#find /usr/share/doc -empty | sudo xargs rmdir
#sudo rm -rf /usr/share/man /usr/share/groff /usr/share/info /usr/share/lintian /usr/share/linda /var/cache/man

df -h | egrep  "[s|v]da"