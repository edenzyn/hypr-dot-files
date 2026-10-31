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
# One fastfetch card (~/.config/fastfetch): image logo, greeting, date and
# weather, system + hardware trees, pending updates and a quote. greet.sh
# refreshes the slow parts (weather, updates) in the background.
function fish_greeting
    ~/.config/fastfetch/greet.sh refresh

    # Draw the card in the shell's accent color (Control Panel → Settings)
    set -l accent "#89B4FA"
    if test -s ~/.local/state/quickshell/accent
        set accent (string trim (command cat ~/.local/state/quickshell/accent))
    end

    # Image logo needs the kitty graphics protocol (ghostty, kitty);
    # other terminals (e.g. VS Code) get the small CachyOS text logo
    set -l logo
    # (also when ~/.config/fastfetch/assets/jett.png is missing, e.g. a fresh install)
    if not test -f ~/.config/fastfetch/assets/jett.png; or begin; not contains -- "$TERM_PROGRAM" ghostty kitty; and test "$TERM" != xterm-kitty; end
        set logo --logo-type builtin --logo CachyOS_small --logo-color-1 $accent --logo-color-2 "#B4BEFE"
    end

    fastfetch --color-keys $accent $logo
end
