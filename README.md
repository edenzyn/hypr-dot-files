# EdenHypr

**The complete Hyprland setup** · Hyprland + Quickshell + ghostty + fish + starship + fastfetch
© 2026 EDEN

- Floating pill bar with media, tray, notifications, control panel, calendar
- Control panel: Wi-Fi/Bluetooth/audio, night light + warmth, caffeine, game mode,
  display projection (extend / mirror / laptop / monitor), accent color, power profiles
- Notifications with a Show button that jumps to the app on any screen
- Clipboard history, wallpaper picker (images + videos), screenshots, screen-share picker
- Terminal welcome card (greeting, weather, updates, system info, a quote)

## Install

Arch-based distros (Arch, CachyOS, EndeavourOS, ...):

```sh
git clone https://github.com/edenzyn/hypr-dot-files
cd hypr-dot-files
./install.sh --dry-run   # optional: see every step first, changes nothing
./install.sh
```

The installer asks:

1. **GNOME / KDE found?** Install **alongside** it (pick at the login screen) or **replace** it
   (asks you to type `REPLACE`, keeps a working login screen).
2. **Primary screen** when two are connected (gets the bar and workspace 1).
3. **Options:** terminal setup, fish as default shell, video wallpapers, night light.
4. **Weather city** for the terminal card (empty = detect automatically).

It then installs packages (official repos first, AUR via `yay`/`paru`), backs up your
current configs to `~/.config/eden-backup-<date>/`, copies EdenHypr in, and adapts it to
your machine (your home folder, monitor names, highest refresh rate). Log out and pick
**Hyprland** at the login screen.

**Undo:** copy the folders from `~/.config/eden-backup-<date>/` back into `~/.config/`.

## Shortcuts

| Keys | Action |
| --- | --- |
| `SUPER+D` | App launcher |
| `SUPER+X` | Terminal |
| `SUPER+A` / `SUPER+I` | Control panel / its Settings |
| `SUPER+V` | Clipboard history |
| `SUPER+W` | Wallpapers |
| `SUPER+S` / `SUPER+Print` | Screenshot area / screen |
| `SUPER+F` / `SUPER+M` | Fullscreen / maximize |
| `SUPER+SHIFT+arrows` / `SUPER+CTRL+arrows` | Move / resize window |
| `SUPER+Q` | Close window |
| `SUPER+L` | Lock |

## Layout

```
install.sh                  EdenHypr installer
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
fastfetch/                  welcome card (config.jsonc + greet.sh);
                            put a logo at fastfetch/assets/ (kept out of git)
```

## Save changes

```sh
cd ~/.config && git add -A && git commit -m "what changed" && git push
```
