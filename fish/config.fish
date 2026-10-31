source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
starship init fish | source
zoxide init fish | source

alias ls="eza --icons"
alias ll="eza -lah --icons"
alias la="eza -la --icons"
alias cat="bat"
alias cls="clear"

fnm env --use-on-cd | source

# ─── Terminal welcome screen ─────────────────────────────────
# fastfetch + greeting + date / weather / pending updates + a random quote.
# Weather and updates are fetched in the background and cached, so opening a
# terminal never waits on the network.
function __greet_refresh --argument-names file max_age cmd
    if not test -s $file; or test (math (date +%s) - (stat -c %Y $file)) -gt $max_age
        fish -c "$cmd > $file.tmp 2>/dev/null; and test -s $file.tmp; and mv $file.tmp $file; or rm -f $file.tmp" &>/dev/null &
        disown 2>/dev/null
    end
end

function fish_greeting
    fastfetch

    set -l cache ~/.cache/terminal-greeting
    mkdir -p $cache
    __greet_refresh $cache/weather 1800 "curl -s --max-time 4 'wttr.in/?format=%c%t+%C' | grep '°'"
    __greet_refresh $cache/updates 10800 "checkupdates 2>/dev/null | wc -l"

    set -l hour (date +%H)
    set -l part evening
    if test $hour -lt 12
        set part morning
    else if test $hour -lt 17
        set part afternoon
    end

    set -l accent 89B4FA
    test -s ~/.local/state/quickshell/accent; and set accent (string replace '#' '' (command cat ~/.local/state/quickshell/accent))

    set -l info (date "+%a, %b %d")
    test -s $cache/weather; and set info "$info   ·   "(string trim (command cat $cache/weather))
    if test -s $cache/updates
        set -l n (string trim (command cat $cache/updates))
        if test "$n" -gt 0 2>/dev/null
            set info "$info   ·   󰚰 $n updates"
        else
            set info "$info   ·   󰄬 up to date"
        end
    end

    set -l quotes \
        "Talk is cheap. Show me the code. - Linus Torvalds" \
        "First, solve the problem. Then, write the code. - John Johnson" \
        "Simplicity is the soul of efficiency. - Austin Freeman" \
        "Make it work, make it right, make it fast. - Kent Beck" \
        "Code is like humor. When you have to explain it, it's bad. - Cory House" \
        "Programs must be written for people to read. - Harold Abelson" \
        "The best error message is the one that never shows up. - Thomas Fuchs" \
        "Deleted code is debugged code. - Jeff Sickel" \
        "It works on my machine. - Every developer, ever" \
        "Ship it. - Everyone at 2 AM"

    echo
    set_color --bold $accent; echo "   Good $part, $USER"
    set_color normal; set_color A9B1D6; echo "   $info"
    set_color 6C7086 --italics; echo "   "$quotes[(random 1 (count $quotes))]
    set_color normal
    echo
end
export PATH="$HOME/.local/bin:$PATH"

function open-bios
    sudo systemctl reboot --firmware-setup
end

export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
