#!/bin/env bash

if [ -z "$1" ]; then
    important_packages="linux systemd"
    ignored_packages="$(grep IgnorePkg /etc/pacman.conf | sed 's/IgnorePkg =//;s/#.*//')"
    mapfile -t upds < <(/usr/bin/pacman -Qqu | grep -Ev "$(echo "$ignored_packages" | tr ' ' '|'))")
    att=""
    for imppkg in $important_packages; do
         for index in ${!upds[*]}; do
             if [[ "${upds[$index]}" =~ ^$imppkg ]]
             then
               upds[index]="<big>${upds[$index]}</big>"
               att="! "
             fi
         done
    done
    [[ ${#upds[*]} -gt 0 ]] && echo "{\"text\": \"$att${#upds[*]}\", \"class\": \"updates\", \"tooltip\": \"${upds[*]}\"}"
elif [ "$1" == "getnews" ]; then
    echo -ne '\033[0;34m:: \033[0m\033[1mRequired by: '; echo -e '\033[0m'; max=$(pacman -Qqu | wc -L); for pkg in $(pacman -Qqu); do printf "%*s:%s\n" "$max" "$pkg" "$(pacman -Qi "$pkg" | grep Req | sed -e 's/Required By     : //g')" | column -c85 -s: -t -W2; done;
    echo -ne '\n\033[0;34m:: \033[0m\033[1mMirror: '"$(grep -m1 -Po '(?<=Server = https:\/\/)[^\/]+' /etc/pacman.d/mirrorlist)"'\033[0m\n\n'
    pikaur -Syu --noedit
    read -n 1 -s -r -p "Press any key to exit..."
fi
