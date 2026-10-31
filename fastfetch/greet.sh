#!/usr/bin/env bash
# Lines for the terminal welcome card (fastfetch "command" modules).
# Everything is read from a cache, so this is instant; slow data (weather,
# updates, Reddit) is refreshed in the background by `greet.sh refresh`.
#   greet.sh hello|today|updates|reddit|quote|refresh
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
    reddit)
        # random post from today's top: "r/sub  title"
        [ -s "$CACHE/reddit" ] && shuf -n 1 "$CACHE/reddit" | cut -c1-70 || echo "loading…"
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
        stale weather 1800 && fetch weather sh -c "curl -s --max-time 4 'wttr.in/?format=%c%t+%C' | grep '°'"
        stale updates 10800 && fetch updates sh -c "checkupdates 2>/dev/null | wc -l"
        # One combined feed request; after a failure (e.g. rate limit) wait 15 min
        # before trying again, and keep showing the last good posts meanwhile
        if stale reddit 7200 && stale reddit.try 900; then
            touch "$CACHE/reddit.try"
            fetch reddit sh -c 'curl -sf --max-time 6 -A "Mozilla/5.0 terminal-greeting/1.0" \
                "https://www.reddit.com/r/unixporn+linux+programming/top/.rss?t=day&limit=15" \
                | python3 -I -c "
import sys, html, xml.etree.ElementTree as ET
ns = {\"a\": \"http://www.w3.org/2005/Atom\"}
root = ET.fromstring(sys.stdin.read())
for e in root.findall(\"a:entry\", ns):
    sub = e.find(\"a:category\", ns).get(\"term\")
    print(\"r/\" + sub + \"  \" + html.unescape(e.find(\"a:title\", ns).text.strip()))
"'
        fi
        ;;
esac
