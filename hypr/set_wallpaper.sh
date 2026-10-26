#!/bin/bash
# Set the wallpaper on all monitors. Images are drawn by Quickshell
# (WallpaperBackground.qml), videos and GIFs are played by mpvpaper.
#   set_wallpaper.sh <file>     apply a new wallpaper
#   set_wallpaper.sh --restore  at login: start the video player if the wallpaper is a video

CUR_FILE="$HOME/.config/hypr/current_wallpaper"
LOCK_IMG="$HOME/Pictures/wall.jpg"

is_video() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.mov|*.gif) return 0 ;;
    esac
    return 1
}

# One mpvpaper per monitor. --profile=fast keeps 4K videos cheap to scale
# (~12% GPU instead of ~86%); Quickshell pauses them through the IPC socket
# while windows cover the screen.
start_video() {
    pkill -x mpvpaper
    for mon in $(hyprctl monitors | awk '/^Monitor/ {print $2}'); do
        setsid -f mpvpaper -o "no-audio --loop-file=inf --hwdec=vaapi --profile=fast --panscan=1.0 --input-ipc-server=$XDG_RUNTIME_DIR/mpvpaper-$mon.sock" \
            "$mon" "$1" >/dev/null 2>&1
    done
}

if [ "$1" = "--restore" ]; then
    WALL=$(cat "$CUR_FILE" 2>/dev/null)
    if [ -f "$WALL" ] && is_video "$WALL"; then
        start_video "$WALL"
    fi
    exit 0
fi

NEW_WALL="$1"
if [ ! -f "$NEW_WALL" ]; then
    echo "File not found: $NEW_WALL" >&2
    exit 1
fi

echo "$NEW_WALL" > "$CUR_FILE"

# hyprlock reads ~/Pictures/wall.jpg, so keep a real JPEG there
# (for videos: a frame from 1s in)
if [ "$NEW_WALL" != "$LOCK_IMG" ]; then
    mkdir -p "$HOME/Pictures"
    case "${NEW_WALL,,}" in
        *.jpg|*.jpeg) cp -f "$NEW_WALL" "$LOCK_IMG" ;;
        *.mp4|*.webm|*.mkv|*.mov|*.gif)
            ffmpeg -y -loglevel error -ss 1 -i "$NEW_WALL" -frames:v 1 -vf scale=1920:-2 "$LOCK_IMG" \
                || ffmpeg -y -loglevel error -i "$NEW_WALL" -frames:v 1 -vf scale=1920:-2 "$LOCK_IMG" ;;
        *) ffmpeg -y -loglevel error -i "$NEW_WALL" "$LOCK_IMG" || cp -f "$NEW_WALL" "$LOCK_IMG" ;;
    esac
fi

if is_video "$NEW_WALL"; then
    # Quickshell fades its image out once the video is playing underneath
    start_video "$NEW_WALL"
    qs ipc call wallpaperbg set "$NEW_WALL"
else
    # Quickshell fades the image in over the video, then the video stops
    qs ipc call wallpaperbg set "$NEW_WALL"
    if pgrep -x mpvpaper >/dev/null; then
        setsid -f sh -c 'sleep 1.5; pkill -x mpvpaper' >/dev/null 2>&1
    fi
fi
