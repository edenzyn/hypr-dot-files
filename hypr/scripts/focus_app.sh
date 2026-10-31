#!/usr/bin/env bash
# Focus an app's window (any screen / workspace), optionally launching it if
# it isn't open. Used by notification "Show" buttons and tray icon clicks.
#   focus_app.sh [--launch <desktop-entry-id>] <name> [name...]
# Names are matched case-insensitively against window class / initial class
# (exact match first, then partial, e.g. "zapzap" ~ "com.rtosta.zapzap").
# Exit 0 if a window was focused or the app launched, 1 otherwise.

LAUNCH=""
if [ "$1" = "--launch" ]; then
    LAUNCH="$2"
    shift 2
fi

ADDR=$(hyprctl clients -j | python3 -I -c '
import json, sys
names = [n.lower().removesuffix(".desktop") for n in sys.argv[1:] if n.strip()]
clients = json.load(sys.stdin)
def keys(c):
    return [c.get("class", "").lower(), c.get("initialClass", "").lower()]
# Most recently used first
clients.sort(key=lambda c: c.get("focusHistoryID", 1 << 30))
for c in clients:                      # exact class match
    if any(n in keys(c) for n in names):
        print(c["address"]); sys.exit()
for c in clients:                      # partial match either way
    for k in keys(c):
        if k and any(n in k or k in n for n in names if len(n) >= 3):
            print(c["address"]); sys.exit()
' "$@")

if [ -n "$ADDR" ]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$ADDR\" })" >/dev/null
    exit 0
fi

if [ -n "$LAUNCH" ]; then
    # Opens on the currently focused screen/workspace
    gtk-launch "${LAUNCH%.desktop}" >/dev/null 2>&1 &
    exit 0
fi

exit 1
