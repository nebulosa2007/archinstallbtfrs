#!/bin/bash

df -h | egrep  "[s|v]da"
sudo pacman -Rsn $(pacman -Qdtq)
sudo pacman -Scc
[ -x /usr/bin/localepurge ]; /usr/bin/localepurge


sudo journalctl --disk-usage
sudo journalctl --vacuum-size=5M
sudo journalctl --verify
sudo journalctl --disk-usage

find /var/log -type f -regex ".*\.gz$" 2> /dev/null | sudo xargs rm -rf
find /var/log -type f -regex ".*\.[0-9]$" 2> /dev/null| sudo xargs rm -rf
find ~/.cache/ -type f 2> /dev/null| sudo xargs rm -rf

df -h | egrep "[s|v]da"