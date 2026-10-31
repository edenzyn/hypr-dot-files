# hypr-dot-files

Hyprland (Lua config, 0.57+) + Quickshell desktop, plus the terminal setup.

## Layout

```
hypr/
├── hyprland.lua            Hyprland: monitors, autostart, look, rules, keybinds
├── hypridle.conf           dim / lock / screen off / suspend timers
├── hyprlock.conf           lock screen
├── xdph.conf               screen-share portal (custom picker)
├── wallpaper_sources.json  folders shown in the wallpaper picker
└── scripts/
    ├── quickshell.sh, refresh.sh       start / restart Quickshell
    ├── set_wallpaper.sh                image (Quickshell) or video (mpvpaper) wallpaper
    ├── get_wallpapers.py, manage_wallpaper_folders.py   wallpaper picker backend
    ├── screenshot.sh                   area / screen screenshot to file + clipboard
    ├── share_picker.sh                 screen-share picker bridge
    ├── focus_app.sh                    focus an app's window (notifications, tray)
    └── session_settings.sh             remember volume / mic / brightness
quickshell/                 bar, launcher, control panel, media player,
                            notifications, clipboard, wallpaper picker
ghostty/config              terminal
fish/config.fish            shell
starship/starship.toml      prompt (fish sets STARSHIP_CONFIG)
fastfetch/                  welcome card (config.jsonc + greet.sh)
```

## Restore on a fresh install

```sh
cd ~/.config
git init -b main
git remote add origin https://github.com/edenzyn/hypr-dot-files.git
git fetch origin
git checkout -f main   # overwrites the tracked files above
```

Packages:

```sh
sudo pacman -S hyprland hypridle hyprlock hyprpolkitagent hyprsunset xdg-desktop-portal-hyprland \
  quickshell cliphist wl-clipboard grim slurp brightnessctl ffmpeg mpvpaper socat zenity \
  ghostty fish starship fastfetch eza bat zoxide pacman-contrib
```

Fonts: Rowdies, Inter, Font Awesome 6, JetBrainsMono Nerd Font. Cursor: phinger-cursors.

## Save changes

```sh
cd ~/.config && git add -A && git commit -m "what changed" && git push
```
