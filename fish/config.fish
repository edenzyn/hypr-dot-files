# ~/.config/fish/config.fish

# ── Base ─────────────────────────────────────────────────────────────
# CachyOS defaults (abbreviations, man pages through bat, ...)
source /usr/share/cachyos-fish-config/cachyos-config.fish

# ── Prompt & tools ───────────────────────────────────────────────────
set -gx STARSHIP_CONFIG $HOME/.config/starship/starship.toml
starship init fish | source        # prompt (~/.config/starship/starship.toml)
zoxide init fish | source          # `z <dir>` smart cd
fnm env --use-on-cd | source       # Node version per project

# ── Aliases ──────────────────────────────────────────────────────────
alias ls="eza --icons"
alias ll="eza -lah --icons"
alias la="eza -la --icons"
alias cat="bat"
alias cls="clear"

# ── Environment ──────────────────────────────────────────────────────
fish_add_path -g $HOME/.local/bin
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx ANDROID_SDK_ROOT $HOME/Android/Sdk
fish_add_path -g $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools

# ── Functions ────────────────────────────────────────────────────────
function open-bios --description "Reboot into the BIOS/UEFI setup"
    sudo systemctl reboot --firmware-setup
end

# ── Welcome screen ───────────────────────────────────────────────────
# One fastfetch card (~/.config/fastfetch): greeting, date/weather, updates,
# a trending Reddit post, system info and a quote. greet.sh refreshes the
# slow parts (weather, updates, Reddit) in the background and caches them.
function fish_greeting
    ~/.config/fastfetch/greet.sh refresh

    # Draw the card in the shell's accent color (Control Panel → Settings)
    set -l accent "#89B4FA"
    if test -s ~/.local/state/quickshell/accent
        set accent (string trim (command cat ~/.local/state/quickshell/accent))
    end
    fastfetch --color-keys $accent --logo-color-1 $accent --logo-color-2 "#B4BEFE"
end
