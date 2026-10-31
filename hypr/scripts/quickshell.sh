#!/bin/sh
# Stop any running instance, wait only until it has actually exited
pkill -x quickshell
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    pgrep -x quickshell >/dev/null || break
    sleep 0.1
done
exec quickshell
