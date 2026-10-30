-- Hyprland config (Lua). Hyprland 0.57 dropped hyprland.conf; this is the
-- converted version of it. Wiki: https://wiki.hypr.land/configuring/

------------------
---- MONITORS ----
------------------

-- laptop left and primary
hl.monitor({ output = "eDP-1",    mode = "1920x1080@120.21", position = "0x0",    scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@100",    position = "1920x0", scale = 1 })

-- monitor left and primary
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@100",    position = "0x0",    scale = 1 })
-- hl.monitor({ output = "eDP-1",    mode = "1920x1080@120.21", position = "1920x0", scale = 1 })
-- hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "nautilus"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- These only apply inside Hyprland, GNOME is not affected
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "phinger-cursors-light")
hl.env("HYPRCURSOR_THEME", "phinger-cursors-light")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")


-------------------
---- AUTOSTART ----
-------------------

-- Portals are DBus-activated on Arch (config: /usr/share/xdg-desktop-portal/hyprland-portals.conf)
hl.on("hyprland.start", function()
    -- Kill any stale hypridle left over from a previous login first, it blocks the
    -- ScreenSaver D-Bus name (breaks idle inhibit and hangs xdg-desktop-portal-gtk)
    hl.exec_cmd("pkill -KILL -x hypridle; hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    -- Quickshell: bar, launcher, panels and the wallpaper (WallpaperBackground.qml)
    hl.exec_cmd("~/.config/hypr/quickshell.sh")
    -- If the wallpaper is a video, start its player (mpvpaper)
    hl.exec_cmd("~/.config/hypr/set_wallpaper.sh --restore")
    -- Clipboard history (cliphist), shown with SUPER+V
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },

    general = {
        gaps_in     = 1,
        gaps_out    = 3,
        border_size = 3,

        col = {
            active_border   = "rgba(121212ee)",
            inactive_border = "rgba(1E1E1Eaa)",
        },

        layout = "dwindle",

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,
    },

    decoration = {
        rounding = 8,

        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    render = {
        direct_scanout = 2,     -- fullscreen games skip compositing (less latency, less GPU work)
        cm_enabled     = false, -- no HDR screens here, skip the color-management pass
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color = "rgb(121213)", -- matches Quickshell, shown before the wallpaper loads
    },
})

-- speed is in deciseconds (1 = 100ms). Lower = snappier.
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "default", style = "popin 10%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4, bezier = "default" })

-- Touchpad: 3-finger swipe left/right switches workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

hl.bind(mainMod .. " + X", exec(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + R", exec("~/.config/hypr/refresh.sh"))
hl.bind(mainMod .. " + E", exec(fileManager))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- true fullscreen (covers the bar)
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))  -- maximize (keeps the bar and gaps)

-- Move focus / move (swap) window / resize window with arrow keys
local dirs = { left = "left", right = "right", up = "up", down = "down" }
local resizeBy = { left = { -40, 0 }, right = { 40, 0 }, up = { 0, -40 }, down = { 0, 40 } }
for key, dir in pairs(dirs) do
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ direction = dir }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = dir }))
    hl.bind(mainMod .. " + CTRL + " .. key,
        hl.dsp.window.resize({ x = resizeBy[key][1], y = resizeBy[key][2], relative = true }),
        { repeating = true }) -- hold to repeat
end

-- Switch workspaces with mainMod + [0-9], move window with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Same with the numpad (NumLock on and off)
local numpad = {
    { "KP_1", "KP_End", 1 }, { "KP_2", "KP_Down", 2 }, { "KP_3", "KP_Next", 3 },
    { "KP_4", "KP_Left", 4 }, { "KP_5", "KP_Begin", 5 }, { "KP_6", "KP_Right", 6 },
    { "KP_7", "KP_Home", 7 }, { "KP_8", "KP_Up", 8 }, { "KP_9", "KP_Prior", 9 },
    { "KP_0", "KP_Insert", 10 },
}
for _, k in ipairs(numpad) do
    for j = 1, 2 do
        hl.bind(mainMod .. " + " .. k[j],         hl.dsp.focus({ workspace = k[3] }))
        hl.bind(mainMod .. " + SHIFT + " .. k[j], hl.dsp.window.move({ workspace = k[3] }))
    end
end

hl.bind("ALT + SHIFT + S", exec('grim -g "$(slurp)" - | wl-copy'))

-- Scroll through workspaces on the current monitor with mainMod + scroll
-- (r = stay on this monitor, includes empty ones; e+1 used to jump to the other screen)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "r-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Apps
hl.bind(mainMod .. " + B", exec("brave"))
hl.bind(mainMod .. " + C", exec("google-chrome-stable"))

-- Brightness / volume keys (work on the lock screen too, brightness/volume repeat when held)
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl s 5%+ && qs ipc call osd brightness"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl s 5%- && qs ipc call osd brightness"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true })
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true })

-- Quickshell
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:launcher"))
-- Fallback IPC trigger if ever needed: hl.bind(mainMod .. " + D", exec("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboard")) -- clipboard history
hl.bind(mainMod .. " + A", exec("qs ipc call control toggle"))
hl.bind(mainMod .. " + I", exec("qs ipc call control openSettings"))
hl.bind(mainMod .. " + L", exec("hyprlock"))
hl.bind(mainMod .. " + escape", exec("qs ipc call power toggle"))
hl.bind(mainMod .. " + W", exec("qs ipc call wallpaper toggle"))

-- Screenshots (saved to ~/Pictures/Screenshots + copied to clipboard)
hl.bind(mainMod .. " + S",     exec("~/.config/hypr/screenshot.sh"))
hl.bind(mainMod .. " + Print", exec("~/.config/hypr/screenshot.sh screen"))


---------------------
---- CURSOR MODE ----
---------------------

-- Keyboard cursor submap (similar to the Mouse mode in Sway). Needs wlrctl + wl-kbptr.
-- Entrypoint: SUPER + SHIFT + C (SUPER + C is Chrome)
hl.bind(mainMod .. " + SHIFT + C", function()
    hl.config({ cursor = { inactive_timeout = 0, hide_on_key_press = false } })
    hl.dispatch(hl.dsp.submap("cursor"))
end)

hl.define_submap("cursor", function()
    -- Jump cursor to a position
    hl.bind("a", exec([[hyprctl dispatch 'hl.dsp.submap("reset")' && wl-kbptr && hyprctl dispatch 'hl.dsp.submap("cursor")']]))

    -- Cursor movement
    hl.bind("j", exec("wlrctl pointer move 0 10"),  { repeating = true })
    hl.bind("k", exec("wlrctl pointer move 0 -10"), { repeating = true })
    hl.bind("l", exec("wlrctl pointer move 10 0"),  { repeating = true })
    hl.bind("h", exec("wlrctl pointer move -10 0"), { repeating = true })

    -- Left / middle / right button
    hl.bind("q", exec("wlrctl pointer click left"))
    hl.bind("w", exec("wlrctl pointer click middle"))
    hl.bind("e", exec("wlrctl pointer click right"))

    -- Scroll up/down and left/right
    hl.bind("f", exec("wlrctl pointer scroll 10 0"),  { repeating = true })
    hl.bind("r", exec("wlrctl pointer scroll -10 0"), { repeating = true })
    hl.bind("t", exec("wlrctl pointer scroll 0 -10"), { repeating = true })
    hl.bind("g", exec("wlrctl pointer scroll 0 10"),  { repeating = true })

    -- Exit cursor submap
    hl.bind("escape", function()
        hl.config({ cursor = { inactive_timeout = 3, hide_on_key_press = true } })
        hl.dispatch(hl.dsp.submap("reset"))
    end)
end)
