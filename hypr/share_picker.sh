#!/usr/bin/env bash
# ~/.config/hypr/share_picker.sh
# Custom screen share picker bridge between xdg-desktop-portal-hyprland and Quickshell

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"

# Chrome/Electron apps (Chrome, Discord, Meet...) open two portal sessions per
# share (one for their own preview, one for the real capture), so the picker
# used to pop up twice. Reuse the answer if a second request comes right after.
CACHE="$XDG_RUNTIME_DIR/xdph_picker_last"
REUSE_SECONDS=15

if [ -f "$CACHE" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    LAST=$(cat "$CACHE")
    if [ "$AGE" -le "$REUSE_SECONDS" ] && [[ "$LAST" =~ ^\[SELECTION\] ]]; then
        case "$LAST" in
            *window:*)
                # Only reuse a window choice if that window still exists
                HANDLE="${LAST##*window:}"
                if [[ "$XDPH_WINDOW_SHARING_LIST" == *"$HANDLE"* ]]; then
                    rm -f "$CACHE"; echo "$LAST"; exit 0
                fi ;;
            *)
                rm -f "$CACHE"; echo "$LAST"; exit 0 ;;
        esac
    fi
fi

FIFO="$XDG_RUNTIME_DIR/xdph_picker_fifo_$$"
mkfifo "$FIFO"
trap 'rm -f "$FIFO"' EXIT

# Send request to Quickshell ScreenSharePicker (silence quickshell logs from portal stdout)
if ! quickshell ipc --any-display call screenshare open "$FIFO" "$XDPH_WINDOW_SHARING_LIST" >/dev/null 2>&1; then
    # Fallback to default picker if Quickshell is not running
    exec /usr/bin/hyprland-share-picker "$@"
fi

# Block waiting for user response from FIFO
read -r SELECTION < "$FIFO"

if [[ "$SELECTION" =~ ^\[SELECTION\] ]]; then
    echo "$SELECTION" > "$CACHE"
    echo "$SELECTION"
    exit 0
fi

exit 1
