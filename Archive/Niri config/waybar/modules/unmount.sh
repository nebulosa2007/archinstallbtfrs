#!/bin/env bash

# Unmount and power off any user mounted drives.
mapfile -t ArrayDisks < <(lsblk -n -p -S -o PATH,TRAN | grep usb | cut -d " " -f1)

if [ ${#ArrayDisks[@]} -gt 0 ]; then
    mapfile -t ArrayNames < <(lsblk -n -S -P -o MODEL,TRAN | grep usb | grep -Po '(?<=MODEL=")[^"]+')

        for i in "${ArrayDisks[@]}"; do
            parts=$(mount | grep "$i" | grep -Po "(?<= on \/run\/media\/$(whoami)\/)[^ ]+" \
                  | tr "\n" "#" | sed 's/#/, /g;s/, $//')
            [ -z "$parts" ] && parts="Not mounted"
            namedisk=$(lsblk -n -S -P -o PATH,MODEL,TRAN | grep -E $i".*usb" | grep -Po '(?<=MODEL=")[^"]+')
            tooltip="$tooltip$namedisk: $parts\n"
        done
        #shellcheck disable=SC2001
        tooltip=$(echo "$tooltip" | sed 's/\\n$//')

    if [ "$1" == "unmount" ]; then
        if [ ${#ArrayDisks[@]} -gt 1 ]; then
            sel=$(echo "$tooltip" | sed 's/\\n/#/g' \
                | tr "#" "\n" | fuzzel --dmenu --index -l${#ArrayDisks[@]})
            [ -z "$sel" ] && exit 0;
        else
            sel=0
        fi

        mapfile -t ArrayParts < <(mount | grep "${ArrayDisks[$sel]}" \
                                | grep -Po ".*(?= on \/run\/media)")

        if [ ${#ArrayParts[@]} -gt 0 ]
        then
            sync
            part=$(mount | grep "$i" | grep -Po "(?<= on \/run\/media\/$(whoami)\/)[^ ]+")
            for i in "${ArrayParts[@]}"; do
                udisksctl unmount -b "$i" \
                || { notify-send "Failed to unmount partition $part!" \
                                 "Please try again later"; exit 1; }
            done
        fi

        udisksctl power-off -b "${ArrayDisks[$sel]}" \
        || { notify-send "Failed to power-off disk $i!" \
                         "Please try again later"; exit 1; }

        pkill -SIGRTMIN+10 waybar
        notify-send "Disk ${ArrayNames[$sel]} can be safely removed"
    else
        echo "{\"text\": \"\", \"class\": \"umount\", \"tooltip\": \"$tooltip\"}"
    fi
fi
