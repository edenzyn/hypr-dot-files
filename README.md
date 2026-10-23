# dotfiles

Hyprland + Quickshell desktop.

- `hypr/`: Hyprland, hypridle, hyprlock, xdph, wallpaper + screenshot scripts
- `quickshell/`: bar, launcher, control panel, clipboard, wallpaper, share picker

## Restore on a fresh install

```sh
cd ~/.config
git init -b main
git remote add origin <this repo's URL>
git fetch origin
git checkout -f main   # overwrites ~/.config/hypr and ~/.config/quickshell
```

Packages used: hyprland hypridle hyprlock hyprpolkitagent xdg-desktop-portal-hyprland
quickshell cliphist grim slurp wl-clipboard brightnessctl ffmpeg wlrctl wl-kbptr ghostty

## Save changes

```sh
cd ~/.config && git add -A && git commit -m "what changed" && git push
```
