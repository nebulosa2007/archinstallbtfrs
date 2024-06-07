#!/usr/bin/env bash

# sudo pacman -S --needed iwd fuzzel
# sudo systemctl enable --now iwd

device=$(iwctl device list | grep -Po "wl[^ ]+" | head -1)
[ -z "$device" ] && { notify-send "Could not detect Wi-Fi device"\
                                  "Please turn on a Wi-Fi adapter or start the iwd.service";\
                     exit 1; }

iwctl station "$device" scan\
      && notify-send "Scanning Wi-Fi networks..." "Please wait"\
      && sleep 5

mapfile -t SINKS < <(iwctl station "$device" get-networks | tail -n +5 | head -n -1\
                    | sed -e "s:\[1;30m::g;s:\[0m::g;s:\*\x1b.*:\*:g;s:\x1b::g;s:\[1;90m>   :*:g"\
                    | tr -s " " | column -t)

network_selected=$(for SINK in "${SINKS[@]}"; do echo "$SINK"; done\
                 | fuzzel --dmenu -l "${#SINKS[@]}" 2>/dev/null | cut -d " " -f1)
[ -z "$network_selected" ] && exit 1

[ "${network_selected:0:1}" = "*" ] && { notify-send "Already connected to ${network_selected:1}"\
                                         "Nothing to do";\
                                         exit 0; }

is_known_network=$(iwctl known-networks list | grep "${network_selected#\**}")
if [ -n "$is_known_network" ]
then
    credentials=$(echo -e "Use saved credentials\nEnter new passphrase\n"\
                | fuzzel --no-fuzzy --dmenu --index -l2 2>/dev/null)
    [ "$credentials" -eq 1 ] && password="--passphrase "$(echo "Enter passphrase for $network_selected"\
                                                        | fuzzel --no-fuzzy --dmenu -l1 -p "> ")
fi

#shellcheck disable=SC2086
connect=$(iwctl $password station "$device" connect "$network_selected")
notify-send "$([ -z "$connect" ] && echo "Connected to $network_selected"\
             || echo "Error connecting to $network_selected" "Please check settings or passphrase")"
