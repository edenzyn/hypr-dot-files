#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  Hyprland Setup · by EDEN                                    │
# │  Hyprland + Quickshell + ghostty + fish + starship + fastfetch│
# │  https://github.com/edenzyn/hypr-dot-files                    │
# ╰──────────────────────────────────────────────────────────────╯
#
#   ./install.sh            interactive install
#   ./install.sh --dry-run  show every step and command, change nothing
#
# Arch-based distros only (Arch, CachyOS, EndeavourOS, ...).
set -euo pipefail

# ── Basics ──────────────────────────────────────────────────────────
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0
fi

BLUE=$'\e[38;2;122;162;247m'; DIM=$'\e[38;2;127;132;156m'; RED=$'\e[38;2;247;118;142m'
GREEN=$'\e[38;2;158;206;106m'; BOLD=$'\e[1m'; RESET=$'\e[0m'

say()  { printf '%s\n' "${BLUE}::${RESET} $*"; }
note() { printf '%s\n' "   ${DIM}$*${RESET}"; }
warn() { printf '%s\n' "${RED}!!${RESET} $*"; }
ok()   { printf '%s\n' "${GREEN}✓${RESET} $*"; }

# Run a command, or only print it in --dry-run mode
run() {
    if [ "$DRY" = 1 ]; then printf '%s\n' "   ${DIM}[dry-run]${RESET} $*"; else "$@"; fi
}

ask_yn() {  # ask_yn "Question" default(y/n) -> returns 0 for yes
    local q="$1" def="$2" a hint="[y/N]"
    [ "$def" = y ] && hint="[Y/n]"
    read -rp "   $q $hint " a || true
    a="${a:-$def}"
    [[ "$a" =~ ^[Yy] ]]
}

ask_choice() {  # ask_choice "Question" option1 option2 ... -> echoes the chosen index (1-based)
    local q="$1"; shift
    local i=1 a
    printf '%s\n' "   $q" >&2
    for o in "$@"; do printf '%s\n' "     ${BOLD}$i${RESET}) $o" >&2; i=$((i + 1)); done
    while true; do
        # No more input (e.g. piped/closed stdin): stop instead of looping forever
        read -rp "   Choose [1-$#]: " a || { echo >&2; warn "No input, stopping (nothing was changed)." >&2; exit 1; }
        if [[ "$a" =~ ^[0-9]+$ ]] && [ "$a" -ge 1 ] && [ "$a" -le $# ]; then echo "$a"; return; fi
    done
}

# ── Banner ──────────────────────────────────────────────────────────
cat <<EOF

${BLUE}${BOLD}   ╭──────────────────────────────────────────────╮
   │               Hyprland  Setup                │
   ╰──────────────────────────────────────────────╯${RESET}
   ${DIM}Hyprland + Quickshell + ghostty + fish · by EDEN${RESET}
EOF
[ "$DRY" = 1 ] && warn "Dry run: nothing will be changed."
echo

# ── 1. Checks ───────────────────────────────────────────────────────
[ "$EUID" -eq 0 ] && { warn "Run this as your normal user, not root (it uses sudo when needed)."; exit 1; }
command -v pacman >/dev/null || { warn "This installer supports Arch-based distros only (needs pacman)."; exit 1; }
command -v sudo >/dev/null || { warn "sudo is required."; exit 1; }
[ -f "$SRC/hypr/hyprland.lua" ] || { warn "Run install.sh from inside the cloned repo."; exit 1; }
ok "Arch-based system, user $USER"

# ── 2. Current desktop ──────────────────────────────────────────────
DE=""
pacman -Q gnome-shell >/dev/null 2>&1 && DE="GNOME"
pacman -Q plasma-workspace >/dev/null 2>&1 && DE="${DE:+$DE + }KDE Plasma"
MODE="alongside"
if [ -n "$DE" ]; then
    say "Found ${BOLD}$DE${RESET} on this system."
    c=$(ask_choice "How should Hyprland Setup be installed?" \
        "Alongside $DE (recommended): pick Hyprland or $DE at the login screen" \
        "Replace $DE: uninstall it and keep only Hyprland")
    [ "$c" = 2 ] && MODE="replace"
fi

# ── 3. Monitors ─────────────────────────────────────────────────────
INTERNAL=""; EXTERNAL=""
for s in /sys/class/drm/card*-*/status; do
    [ "$(cat "$s" 2>/dev/null)" = connected ] || continue
    name="$(basename "$(dirname "$s")")"; name="${name#card*-}"
    case "$name" in
        eDP*|LVDS*|DSI*) [ -z "$INTERNAL" ] && INTERNAL="$name" ;;
        *)               [ -z "$EXTERNAL" ] && EXTERNAL="$name" ;;
    esac
done
# Desktop with one monitor: treat it as the "main" screen
if [ -z "$INTERNAL" ] && [ -n "$EXTERNAL" ]; then INTERNAL="$EXTERNAL"; EXTERNAL=""; fi
say "Screens: ${BOLD}${INTERNAL:-none found}${RESET}${EXTERNAL:+ + ${BOLD}$EXTERNAL${RESET}}"
PRIMARY="$INTERNAL"; DISPLAY_MODE="extend"
if [ -n "$EXTERNAL" ]; then
    c=$(ask_choice "Which screen is primary (top bar, workspace 1, on the left)?" \
        "$INTERNAL (built-in)" "$EXTERNAL (external)")
    [ "$c" = 2 ] && PRIMARY="$EXTERNAL"
else
    DISPLAY_MODE="laptop"
fi

# ── 4. Options ──────────────────────────────────────────────────────
say "Options"
ask_yn "Terminal setup (ghostty, fish, starship, fastfetch welcome card)?" y && TERMINAL=1 || TERMINAL=0
FISH_DEFAULT=0
if [ "$TERMINAL" = 1 ]; then
    ask_yn "Make fish your default shell?" y && FISH_DEFAULT=1
fi
ask_yn "Video wallpapers (mpvpaper)?" y && VIDEO=1 || VIDEO=0
ask_yn "Night light (hyprsunset)?" y && NIGHT=1 || NIGHT=0
CITY=""
if [ "$TERMINAL" = 1 ]; then
    read -rp "   Weather city for the terminal card (empty = detect automatically): " CITY || true
fi

# ── 5. Summary ──────────────────────────────────────────────────────
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CFG/hyprland-setup-backup-$STAMP"
echo
say "Summary"
note "Install mode:      $MODE${DE:+ ($DE)}"
note "Screens:           primary $PRIMARY${EXTERNAL:+, second ${INTERNAL/$PRIMARY/$EXTERNAL}} ($DISPLAY_MODE)"
note "Terminal setup:    $([ $TERMINAL = 1 ] && echo yes || echo no)$([ $FISH_DEFAULT = 1 ] && echo ', fish as default shell')"
note "Video wallpapers:  $([ $VIDEO = 1 ] && echo yes || echo no)"
note "Night light:       $([ $NIGHT = 1 ] && echo yes || echo no)"
note "Existing configs:  backed up to $BACKUP"
echo
ask_yn "Start the installation?" y || { say "Cancelled, nothing changed."; exit 0; }

if [ "$MODE" = replace ]; then
    warn "This will UNINSTALL $DE. Your files stay, but its apps and settings tools go away."
    read -rp "   Type REPLACE to confirm: " confirm || true
    [ "$confirm" = REPLACE ] || { say "Not confirmed, keeping $DE (installing alongside)."; MODE="alongside"; }
fi

# ── 6. Packages ─────────────────────────────────────────────────────
PKGS=(hyprland hypridle hyprlock hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
      quickshell qt6-multimedia-ffmpeg cliphist wl-clipboard grim slurp brightnessctl ffmpeg socat
      zenity imagemagick python pacman-contrib gnome-keyring networkmanager pipewire wireplumber
      power-profiles-daemon ttf-jetbrains-mono-nerd otf-font-awesome inter-font)
OPTIONAL_AUR=(phinger-cursors wlrctl wl-kbptr)
[ "$TERMINAL" = 1 ] && PKGS+=(ghostty fish starship fastfetch eza bat zoxide)
[ "$VIDEO" = 1 ] && PKGS+=(mpvpaper)
[ "$NIGHT" = 1 ] && PKGS+=(hyprsunset)

# Split into official-repo packages and AUR packages
REPO=(); AUR=()
for p in "${PKGS[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then REPO+=("$p"); else AUR+=("$p"); fi
done
AUR+=("${OPTIONAL_AUR[@]}")

say "Installing ${#REPO[@]} packages from the official repos"
run sudo pacman -S --needed "${REPO[@]}"

HELPER="$(command -v yay || command -v paru || true)"
if [ -n "$HELPER" ]; then
    say "Installing from the AUR with $(basename "$HELPER"): ${AUR[*]}"
    run "$HELPER" -S --needed "${AUR[@]}" || warn "Some AUR packages failed; the setup still works without them."
else
    warn "No AUR helper (yay/paru) found. Skipping: ${AUR[*]}"
    note "Install yay later and run: yay -S ${AUR[*]}"
fi

# ── 7. Configs (backup first) ───────────────────────────────────────
DIRS=(hypr quickshell)
[ "$TERMINAL" = 1 ] && DIRS+=(ghostty fish starship fastfetch)

if [ "$SRC" = "$CFG" ]; then
    note "Running from ~/.config itself: configs are already in place."
else
    say "Backing up existing configs to $BACKUP"
    run mkdir -p "$BACKUP"
    for d in "${DIRS[@]}"; do
        [ -e "$CFG/$d" ] && run cp -a "$CFG/$d" "$BACKUP/"
    done
    # Copy only this setup's files over; anything else in these folders
    # (e.g. fish_variables, completions) is left alone
    say "Copying Hyprland Setup configs"
    for d in "${DIRS[@]}"; do
        run mkdir -p "$CFG/$d"
        run cp -a "$SRC/$d/." "$CFG/$d/"
    done
fi

# ── 8. Personalize for this machine ─────────────────────────────────
if [ "$SRC" != "$CFG" ]; then
say "Adapting configs to this machine"
# Only files that came from the repo
FILES=()
for d in "${DIRS[@]}"; do
    while IFS= read -r -d '' f; do
        grep -qE '/home/edenzyn|eDP-1|HDMI-A-1' "$f" 2>/dev/null && FILES+=("$CFG/${f#"$SRC"/}")
    done < <(find "$SRC/$d" -type f -print0)
done
for f in "${FILES[@]}"; do
    run sed -i "s#/home/edenzyn#$HOME#g" "$f"
    # Monitor names: built-in -> INTERNAL, external -> EXTERNAL (placeholder keeps working if absent)
    run sed -i -e "s/eDP-1/__EDEN_INT__/g" -e "s/HDMI-A-1/__EDEN_EXT__/g" "$f"
    run sed -i -e "s/__EDEN_INT__/${INTERNAL:-eDP-1}/g" -e "s/__EDEN_EXT__/${EXTERNAL:-HDMI-A-1}/g" "$f"
done
# Each screen at its highest refresh rate
run sed -i -E 's/= "1920x1080@[0-9.]+"/= "highrr"/g' "$CFG/hypr/hyprland.lua"

# Wallpaper folders: the user's own Pictures/Videos
run mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Videos/wallpapers"
if [ "$DRY" = 1 ]; then
    note "[dry-run] write $CFG/hypr/wallpaper_sources.json"
else
    printf '[\n  "%s",\n  "%s"\n]\n' "$HOME/Pictures/wallpapers" "$HOME/Videos/wallpapers" > "$CFG/hypr/wallpaper_sources.json"
fi

# Display layout (Control Panel → Settings changes it later)
run mkdir -p "$HOME/.local/state/hypr"
if [ "$DRY" = 1 ]; then
    note "[dry-run] write ~/.local/state/hypr/display: primary=$PRIMARY mode=$DISPLAY_MODE"
else
    printf 'primary=%s\nmode=%s\n' "$PRIMARY" "$DISPLAY_MODE" > "$HOME/.local/state/hypr/display"
fi

fi  # end: fresh install only

if [ "$TERMINAL" = 1 ] && [ -n "$CITY" ]; then
    if [ "$DRY" = 1 ]; then note "[dry-run] weather city: $CITY"; else echo "$CITY" > "$CFG/fastfetch/weather-city"; fi
fi
run chmod +x "$CFG"/hypr/scripts/*.sh "$CFG"/hypr/scripts/*.py
[ "$TERMINAL" = 1 ] && run chmod +x "$CFG/fastfetch/greet.sh"

# ── 9. System setup ─────────────────────────────────────────────────
if [ "$FISH_DEFAULT" = 1 ] && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v fish || echo /usr/bin/fish)" ]; then
    say "Setting fish as your default shell"
    run chsh -s /usr/bin/fish
fi

# A login screen is needed to pick Hyprland
if ! systemctl is-enabled display-manager.service >/dev/null 2>&1; then
    say "No login screen is enabled; installing SDDM"
    run sudo pacman -S --needed sddm
    run sudo systemctl enable sddm.service
fi

if [ "$MODE" = replace ]; then
    # Keep a working login screen before removing GNOME's (GDM)
    if pacman -Q gdm >/dev/null 2>&1 && [[ "$DE" == *GNOME* ]]; then
        say "Switching the login screen from GDM to SDDM"
        run sudo pacman -S --needed sddm
        run sudo systemctl disable gdm.service
        run sudo systemctl enable sddm.service
    fi
    [[ "$DE" == *GNOME* ]] && { say "Removing GNOME"; run sudo pacman -Rns $(pacman -Qgq gnome 2>/dev/null) gnome-shell; }
    [[ "$DE" == *KDE* ]]   && { say "Removing KDE Plasma"; run sudo pacman -Rns $(pacman -Qgq plasma 2>/dev/null); }
fi

# ── Done ────────────────────────────────────────────────────────────
echo
ok "${BOLD}Hyprland Setup is installed.${RESET}"
note "Log out and pick ${BOLD}Hyprland${RESET}${DIM} at the login screen."
note "Shortcuts: SUPER+D apps · SUPER+X terminal · SUPER+A control panel · SUPER+W wallpapers"
[ "$SRC" != "$CFG" ] && note "Your old configs are in $BACKUP"
echo
