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

#function fish_greeting
#    # smth smth
#end
export PATH="$HOME/.local/bin:$PATH"

function open-bios
    sudo systemctl reboot --firmware-setup
end

export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
