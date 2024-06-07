#!/bin/env bash

echo "Toggle switch VPN: $1 interface..."
switcher=$( [ -d /proc/sys/net/ipv4/conf/"$1" ] && echo "stop" || echo "start";)
sudo systemctl "$switcher" wg-quick@"$1"
case ${switcher} in
    "start") notify-send ' VPN is ON';;
     "stop") notify-send ' VPN is OFF';;
esac
