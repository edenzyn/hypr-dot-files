#!/usr/bin/env bash
# Remember volume, mic and screen brightness across restarts.
#   session_settings.sh save     (Quickshell runs this every 30s; writes only on change)
#   session_settings.sh restore  (Hyprland runs this at login)
STATE="$HOME/.local/state/quickshell/settings"
mkdir -p "$(dirname "$STATE")"

vol_of() {  # prints "<volume> <muted 0/1>" for a wpctl target
    local out; out=$(wpctl get-volume "$1" 2>/dev/null) || return 1
    local v; v=$(awk '{print $2}' <<<"$out")
    [[ "$out" == *MUTED* ]] && echo "$v 1" || echo "$v 0"
}

case "$1" in
    save)
        read -r SV SM < <(vol_of @DEFAULT_AUDIO_SINK@) || exit 0
        read -r MV MM < <(vol_of @DEFAULT_AUDIO_SOURCE@) || exit 0
        BR=$(brightnessctl -m -c backlight 2>/dev/null | cut -d, -f4 | tr -d '%')
        # Don't remember the idle-dimmed (or zero) brightness
        if [ -z "$BR" ] || [ "$BR" -le 2 ]; then
            BR=$(grep -s '^brightness=' "$STATE" | cut -d= -f2)
        fi
        NEW=$(printf 'sink_volume=%s\nsink_muted=%s\nmic_volume=%s\nmic_muted=%s\nbrightness=%s\n' \
            "$SV" "$SM" "$MV" "$MM" "$BR")
        [ "$NEW" != "$(cat "$STATE" 2>/dev/null)" ] && echo "$NEW" > "$STATE"
        ;;
    restore)
        [ -f "$STATE" ] || exit 0
        # shellcheck disable=SC1090
        . "$STATE"
        # Wait for PipeWire to be up (login)
        for _ in $(seq 1 20); do wpctl get-volume @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1 && break; sleep 0.5; done
        [ -n "$sink_volume" ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ "$sink_volume"
        [ -n "$sink_muted" ]  && wpctl set-mute @DEFAULT_AUDIO_SINK@ "$sink_muted"
        [ -n "$mic_volume" ]  && wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$mic_volume"
        [ -n "$mic_muted" ]   && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ "$mic_muted"
        [ -n "$brightness" ] && [ "$brightness" -gt 2 ] && brightnessctl -q -c backlight set "${brightness}%"
        ;;
    *)
        echo "usage: $0 save|restore" >&2; exit 1 ;;
esac
