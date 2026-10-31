#!/usr/bin/env bash
# Lines for the terminal welcome card (fastfetch "command" modules).
# Everything is read from a cache, so this is instant; slow data (weather,
# updates) is refreshed in the background by `greet.sh refresh`.
#   greet.sh hello|today|updates|quote|refresh
CACHE="$HOME/.cache/terminal-greeting"
mkdir -p "$CACHE"

# Re-fetch a cache file in the background when it's older than $2 seconds
stale() { [ ! -s "$CACHE/$1" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE/$1") )) -gt "$2" ]; }
fetch() {  # fetch <file> <command...>: write atomically, keep the old file on failure
    local f="$CACHE/$1"; shift
    ( "$@" > "$f.tmp" 2>/dev/null && [ -s "$f.tmp" ] && mv "$f.tmp" "$f" || rm -f "$f.tmp" ) &
}

case "$1" in
    hello)
        h=$(date +%-H)
        if   [ "$h" -lt 12 ]; then part="morning"
        elif [ "$h" -lt 17 ]; then part="afternoon"
        else part="evening"; fi
        echo "Good $part, $USER"
        ;;
    today)
        line="$(date '+%a, %b %-d')"
        [ -s "$CACHE/weather" ] && line="$line  ·  $(<"$CACHE/weather")"
        echo "$line"
        ;;
    updates)
        n=$(cat "$CACHE/updates" 2>/dev/null)
        if [ -z "$n" ]; then echo "checking…"
        elif [ "$n" -gt 0 ]; then echo "$n pending  (sudo pacman -Syu)"
        else echo "system up to date"; fi
        ;;
    cpu)
        # "<model>  ·  <usage>%" (usage sampled over 0.15 s)
        model=$(sed -n 's/^model name\s*: //p' /proc/cpuinfo | head -1 | sed -e 's/ with .*//' -e 's/ [0-9]*-Core Processor//')
        read -r _ a1 a2 a3 a4 a5 a6 a7 _ < /proc/stat; sleep 0.15
        read -r _ b1 b2 b3 b4 b5 b6 b7 _ < /proc/stat
        idle=$(( (b4 + b5) - (a4 + a5) ))
        total=$(( (b1+b2+b3+b4+b5+b6+b7) - (a1+a2+a3+a4+a5+a6+a7) ))
        echo "$model  ·  $(( total > 0 ? 100 * (total - idle) / total : 0 ))%"
        ;;
    gpu)
        busy=""; other=""
        # One line per GPU: usage % where the driver reports it (amdgpu, i915/xe),
        # otherwise active/sleeping (read without waking e.g. an NVIDIA dGPU)
        for c in /sys/class/drm/card[0-9]*; do
            [ -e "$c/device/vendor" ] || continue
            name=$(lspci -s "$(basename "$(readlink -f "$c/device")")" -mm 2>/dev/null \
                   | awk -F'"' '{print $6}' | grep -o '\[[^]]*\]' | tr -d '[]' | sed 's| / .*||')
            [ -z "$name" ] && continue
            if [ -r "$c/device/gpu_busy_percent" ]; then
                busy+="$name  ·  $(cat "$c/device/gpu_busy_percent")%"$'\n'
            else
                state=$(cat "$c/device/power/runtime_status" 2>/dev/null)
                [ "$state" = suspended ] && state="sleeping"
                other+="$name  ·  ${state:-on}"$'\n'
            fi
        done
        # GPUs with a usage % first; `greet.sh gpu N` prints only line N
        out="${busy:-}${other:-}"
        if [ -n "${2:-}" ]; then sed -n "${2}p" <<<"$out"; else printf '%s' "$out"; fi
        ;;
    quote)
        shuf -n 1 <<'EOF'
Talk is cheap. Show me the code.  - Linus Torvalds
First, solve the problem. Then, write the code.  - John Johnson
Simplicity is the soul of efficiency.  - Austin Freeman
Make it work, make it right, make it fast.  - Kent Beck
Programs must be written for people to read.  - Harold Abelson
Deleted code is debugged code.  - Jeff Sickel
The best error message is the one that never shows up.  - Thomas Fuchs
Any fool can write code a computer understands.  - Martin Fowler
It works on my machine.  - every developer, ever
EOF
        ;;
    refresh)
        # Optional fixed city in ~/.config/fastfetch/weather-city (else located by IP)
        city=""
        [ -s "$HOME/.config/fastfetch/weather-city" ] && city=$(tr ' ' '+' < "$HOME/.config/fastfetch/weather-city")
        stale weather 1800 && fetch weather sh -c "curl -s --max-time 4 'wttr.in/${city}?format=%c%t+%C' | grep '°'"
        stale updates 10800 && fetch updates sh -c "checkupdates 2>/dev/null | wc -l"
        ;;
esac
