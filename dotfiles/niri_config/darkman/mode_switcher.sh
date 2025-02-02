#!/bin/env bash

## INSTALLATION:
## install the darkman package
# mkdir -p $HOME/.config/darkman

## Put this script to $HOME/.config/darkman and make it executable:
# chmod +x $HOME/.config/darkman/mode_switcher.sh

## Some tuning the darkman for using only one script at one folder:
# sudo ln -s $HOME/.config/darkman /usr/share/dark-mode.d
# sudo ln -s $HOME/.config/darkman /usr/share/light-mode.d

## Fix visibility the NIRI_SOCKET variable for systemd service darkman:
## ~/.config/systemd/user/darkman.service:
# [Unit]
# PartOf=graphical-session.target
# After=graphical-session.target
# Requisite=graphical-session.target
#
# [Service]
# ExecStart=/usr/bin/darkman run
# Restart=on-failure

## Started together with niri.service:
# ln -s ~/.config/systemd/user/darkman.service ~/.config/systemd/user/niri.service.wants/

## Start service:
# systemctl --user daemon-reload && systemctl start --user darkman

case $(darkman get) in
light)
    # Make sure that you set env parmeter QT_QPA_PLATFORMTHEME=gtk3 for QT applications
    # Set mode for GTK3 applications
        gsettings set org.gnome.desktop.interface gtk-theme Adwaita
    # Set mode for GTK4 applications
        niri msg action do-screen-transition && gsettings set org.gnome.desktop.interface color-scheme prefer-light

    # Switch wallpaper
        ln -sf "$HOME"/Pictures/Wallpapers/niri_light.jpg "$HOME"/.config/niri/wallpaper
        systemctl restart --user swaybg
    # Set brightness
        brightnessctl -q s 14
    # Set mako
        makoctl mode -r dark
    # Set fuzzel
        ln -sf "$HOME"/.config/fuzzel/light_fuzzel.ini "$HOME"/.config/fuzzel/fuzzel.ini

    # Notification
        notify-send -c "system" "  Light mode"
    ;;
dark)
    # Set mode for GTK3 applications. Install arc-gtk-theme, because there is no Adwaita-dark theme anymore
        gsettings set org.gnome.desktop.interface gtk-theme Arc-Dark
    # Set mode for GTK4 applications
        niri msg action do-screen-transition && gsettings set org.gnome.desktop.interface color-scheme prefer-dark

    # Switch wallpaper
        ln -sf "$HOME"/Pictures/Wallpapers/niri_dark.jpg "$HOME"/.config/niri/wallpaper
        systemctl restart --user swaybg
    # Set brightness
        brightnessctl -q s 12
    # Set mako
        makoctl mode -s dark
    # Set fuzzel
        ln -sf "$HOME"/.config/fuzzel/dark_fuzzel.ini "$HOME"/.config/fuzzel/fuzzel.ini

    # Notification (for debug purposes)
        notify-send -c "system" "  Dark mode"
    ;;
esac
