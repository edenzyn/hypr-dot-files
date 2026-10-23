#!/bin/bash
NEW_WALL="$1"
if [ ! -f "$NEW_WALL" ]; then
    echo "File not found: $NEW_WALL" >&2
    exit 1
fi

echo "$NEW_WALL" > "$HOME/.config/hypr/current_wallpaper"

# hyprlock reads ~/Pictures/wall.jpg, so keep a real JPEG copy there
if [ "$NEW_WALL" != "$HOME/Pictures/wall.jpg" ]; then
    mkdir -p "$HOME/Pictures"
    case "${NEW_WALL,,}" in
        *.jpg|*.jpeg) cp -f "$NEW_WALL" "$HOME/Pictures/wall.jpg" ;;
        *) ffmpeg -y -loglevel error -i "$NEW_WALL" "$HOME/Pictures/wall.jpg" || cp -f "$NEW_WALL" "$HOME/Pictures/wall.jpg" ;;
    esac
fi

# Trigger smooth animated cross-fade transition in Quickshell
qs ipc call wallpaperbg set "$NEW_WALL"
