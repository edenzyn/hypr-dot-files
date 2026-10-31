# hypr-dot-files

Hyprland (Lua config, 0.57+) + Quickshell desktop, plus the terminal setup.

- `hypr/`: Hyprland (`hyprland.lua`), hypridle, hyprlock, screen-share picker, wallpaper + screenshot scripts
- `quickshell/`: floating bar, launcher, control panel, media player, notifications, clipboard, wallpaper picker
- `ghostty/`, `fish/config.fish`, `starship.toml`, `fastfetch/`: terminal, shell, prompt, welcome screen

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
  ghostty fish starship fastfetch eza bat zoxide
```

Fonts: Rowdies, Inter, Font Awesome 6, JetBrainsMono Nerd Font. Cursor: phinger-cursors.

## Save changes

```sh
cd ~/.config && git add -A && git commit -m "what changed" && git push
```
