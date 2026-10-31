#!/usr/bin/env bash
# Screenshot: saves to ~/Pictures/Screenshots and copies to clipboard
#   screenshot.sh          -> select a region
#   screenshot.sh screen   -> whole focused monitor
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

if [ "$1" = "screen" ]; then
    MON=$(hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['monitor'])")
    grim -o "$MON" "$FILE" || exit 1
else
    GEOM=$(slurp) || exit 0   # Esc cancels
    grim -g "$GEOM" "$FILE" || exit 1
fi

wl-copy < "$FILE"
notify-send -i "$FILE" "Screenshot saved" "Copied to clipboard"
