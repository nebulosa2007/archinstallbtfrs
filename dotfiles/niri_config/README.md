![image](https://github.com/YaLTeR/niri/assets/85841412/ccc6aaab-fbcc-4135-86c1-b81fbdb97c58)

Installation:

1. Copy all folders to `~/.config`
2. Install needed software

   For Niri:
   ```
   wl-clipboard cliphist polkit-gnome playerctl swaybg wlsunset
   mako waybar libpulse gnome-console brightnessctl libnotify darkman
   ```

   Optional:
   ```
   ly meld nautilus libreoffice-fresh
   ```

   For Waybar (for this config):
   ```
   blueman brightnessctl cliphist curl fuzzel gnome-weather gsconnect iwd jq
   libnotify mpv mpv-mpris openresolv otf-font-awesome paru pavucontrol pipewire-media-session
   polkit power-profiles-daemon pulseaudio pulseaudio-alsa pulseaudio-bluetooth python-pydbus
   ttf-font-logos wireguard-tools wl-clipboard ydotool
   ```

Also check instructions for waybar: `head -7 ~/.config/waybar/config.jsonc`

3. Niri settings:

   Make a link to wallpaper:
   `ln -sf ~/Pictures/Wallpapers/niri_light.jpg ~/.config/niri/wallpaper`

   Needed services:
```console
                                         mkdir -p      ~/.config/systemd/user/niri.service.wants
ln -s ~/.config/systemd/user/cliphist.service          ~/.config/systemd/user/niri.service.wants/
ln -s ~/.config/systemd/user/darkman.service           ~/.config/systemd/user/niri.service.wants/
ln -s /usr/lib/systemd/user/mako.service               ~/.config/systemd/user/niri.service.wants/
ln -s /usr/lib/systemd/user/gnome-polkit-agent.service ~/.config/systemd/user/niri.service.wants/
ln -s ~/.config/systemd/user/playctld.service          ~/.config/systemd/user/niri.service.wants/
ln -s ~/.config/systemd/user/swaybg.service            ~/.config/systemd/user/niri.service.wants/
ln -s /usr/lib/systemd/user/waybar.service             ~/.config/systemd/user/niri.service.wants/
ln -s ~/.config/systemd/user/wlsunset.service          ~/.config/systemd/user/niri.service.wants/
ln -s ~/.config/systemd/user/ydotool.service           ~/.config/systemd/user/niri.service.wants/
ln -s /usr/lib/systemd/user/xwayland-satellite.service ~/.config/systemd/user/niri.service.wants/
```
4. Other settings:

   Put your client wireguard config to `/etc/wireguard/wg0.conf`

   `sudo usermod -aG input $USER` AND REBOOT


`Niri` session should appear in your Login Manager.


Please read also:

https://github.com/YaLTeR/niri/wiki/Example-systemd-Setup

https://github.com/YaLTeR/niri/wiki/Important-Software

Debug or view log:
`systemctl --user status waybar`
