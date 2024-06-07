#!/bin/env bash

COUNTUPD=$(/usr/bin/pacman -Qu | grep -v "\[ignored\]" | /usr/bin/wc -l)
IMPPKGS="linux"
PKGUPD=$(/usr/bin/pacman -Qqu | sed 's/linux /<big>linux<\/big> /')
IMP=$([[ `/usr/bin/pacman -Qqu | egrep ^$IMPPKGS$ 2>/dev/null | wc -l` -ne 0 ]] && echo "! ")

[[ $COUNTUPD -gt 0 ]] && echo '{"text":"'$IMP$COUNTUPD'", "class": "updates", "tooltip":"'$PKGUPD'"}'
