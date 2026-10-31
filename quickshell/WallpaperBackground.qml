import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// One shared wallpaper path, drawn on every monitor.
// Images are drawn here. Videos/GIFs are played by mpvpaper (started by
// ~/.config/hypr/scripts/set_wallpaper.sh); these windows fade out and unmap so the
// video underneath shows, and they pause it while windows cover the screen.
Scope {
    id: wallpaperRoot

    property string currentPath: ""
    readonly property bool isVideo: isVideoPath(currentPath)
    property bool videoShown: false   // windows unmapped, mpvpaper visible
    property real contentOpacity: 1.0

    signal videoStarted()

    function isVideoPath(p) {
        return /\.(mp4|webm|mkv|mov|gif)$/i.test(p || "")
    }

    // Initial read of active wallpaper
    Process {
        id: readInitProc
        running: true
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/current_wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim()
                if (!p || p.length === 0) {
                    p = Quickshell.env("HOME") + "/Pictures/wall.jpg"
                }
                wallpaperRoot.currentPath = p
            }
        }
    }

    IpcHandler {
        target: "wallpaperbg"
        function set(path: string) {
            if (path) wallpaperRoot.currentPath = path
        }
    }

    onCurrentPathChanged: {
        // Check the path directly, the isVideo binding may not have updated yet
        if (isVideoPath(currentPath)) {
            fadeInAnim.stop()
            videoRevealTimer.restart()
        } else {
            videoRevealTimer.stop()
            fadeOutAnim.stop()
            if (videoShown || contentOpacity < 1) {
                // Coming back from a video: map windows on top and fade the image in
                contentOpacity = 0
                videoShown = false
                fadeInAnim.restart()
            }
        }
    }

    // Give mpvpaper time to show its first frame before revealing it
    Timer {
        id: videoRevealTimer
        interval: 900
        onTriggered: {
            if (!wallpaperRoot.videoShown) fadeOutAnim.restart()
            wallpaperRoot.videoStarted()
        }
    }

    SequentialAnimation {
        id: fadeOutAnim
        NumberAnimation {
            target: wallpaperRoot
            property: "contentOpacity"
            to: 0.0
            duration: 500
            easing.type: Easing.InOutCubic
        }
        ScriptAction { script: wallpaperRoot.videoShown = true }
    }

    NumberAnimation {
        id: fadeInAnim
        target: wallpaperRoot
        property: "contentOpacity"
        to: 1.0
        duration: 650
        easing.type: Easing.InOutCubic
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Floating state comes from lastIpcObject, which needs a refresh
            if (["openwindow", "changefloatingmode", "movewindowv2"].includes(event.name)) Hyprland.refreshToplevels()
            // A newly plugged-in monitor needs its own video player
            if (event.name === "monitoraddedv2" && wallpaperRoot.isVideo) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/set_wallpaper.sh", "--restore"])
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: wallpaperBgWindow

            required property var modelData
            screen: modelData
            visible: !wallpaperRoot.videoShown

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"
            exclusiveZone: -1
            color: "transparent"

            property string shownPath: ""
            property bool activeIsA: true
            property bool isInitialized: false

            Component.onCompleted: transitionTo(wallpaperRoot.currentPath)

            Connections {
                target: wallpaperRoot
                function onCurrentPathChanged() {
                    wallpaperBgWindow.transitionTo(wallpaperRoot.currentPath)
                }
                function onVideoStarted() {
                    pauseTimer.restart()
                }
            }

            function transitionTo(path) {
                if (!path || path === shownPath) return
                shownPath = path
                if (wallpaperRoot.isVideoPath(path)) return // mpvpaper draws it

                // First image, or fading in over a video: show it directly, no cross-fade
                if (!isInitialized || wallpaperRoot.contentOpacity < 1) {
                    activeIsA = true
                    imgA.source = "file://" + path
                    imgA.opacity = 1.0
                    imgA.scale = 1.0
                    imgB.opacity = 0.0
                    isInitialized = true
                    return
                }

                if (activeIsA) {
                    imgB.scale = 1.05
                    imgB.opacity = 0.0
                    imgB.source = "file://" + path
                } else {
                    imgA.scale = 1.05
                    imgA.opacity = 0.0
                    imgA.source = "file://" + path
                }
            }

            // ─── Pause the video while windows cover this screen ──────
            readonly property var activeWs: {
                let mon = Hyprland.monitorFor(modelData)
                return mon ? mon.activeWorkspace : null
            }
            readonly property bool covered: {
                if (!activeWs) return false
                if (activeWs.hasFullscreen) return true
                let tl = activeWs.toplevels.values
                for (let i = 0; i < tl.length; i++) {
                    let ipc = tl[i].lastIpcObject
                    if (!ipc || ipc.floating !== true) return true // tiled windows fill the screen
                }
                return false
            }
            onCoveredChanged: if (wallpaperRoot.isVideoPath(wallpaperRoot.currentPath)) pauseTimer.restart()

            // Debounced, so fast workspace switching doesn't spam mpv
            Timer {
                id: pauseTimer
                interval: 250
                onTriggered: {
                    if (!wallpaperRoot.isVideoPath(wallpaperRoot.currentPath)) return
                    let sock = Quickshell.env("XDG_RUNTIME_DIR") + "/mpvpaper-" + wallpaperBgWindow.modelData.name + ".sock"
                    let cmd = JSON.stringify({ command: ["set_property", "pause", wallpaperBgWindow.covered] })
                    Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | socat - UNIX-CONNECT:\"$2\" >/dev/null 2>&1", "sh", cmd, sock])
                }
            }

            Item {
                anchors.fill: parent
                opacity: wallpaperRoot.contentOpacity

                Rectangle {
                    anchors.fill: parent
                    color: "#121213"
                }

                // ─── Image A ──────────────────────────────────────────────
                Image {
                    id: imgA
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    opacity: 0.0
                    scale: 1.0
                    // Decode at screen size instead of full 5K resolution
                    sourceSize.width: wallpaperBgWindow.width
                    sourceSize.height: wallpaperBgWindow.height

                    onStatusChanged: {
                        if (status === Image.Ready && wallpaperBgWindow.isInitialized && !wallpaperBgWindow.activeIsA) {
                            fadeAnimA.restart()
                            scaleAnimA.restart()
                            fadeAnimB_out.restart()
                            wallpaperBgWindow.activeIsA = true
                        }
                    }

                    NumberAnimation {
                        id: fadeAnimA
                        target: imgA
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 650
                        easing.type: Easing.InOutCubic
                    }

                    NumberAnimation {
                        id: scaleAnimA
                        target: imgA
                        property: "scale"
                        from: 1.05
                        to: 1.0
                        duration: 850
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: fadeAnimA_out
                        target: imgA
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: 650
                        easing.type: Easing.InOutCubic
                    }
                }

                // ─── Image B ──────────────────────────────────────────────
                Image {
                    id: imgB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    opacity: 0.0
                    scale: 1.0
                    sourceSize.width: wallpaperBgWindow.width
                    sourceSize.height: wallpaperBgWindow.height

                    onStatusChanged: {
                        if (status === Image.Ready && wallpaperBgWindow.isInitialized && wallpaperBgWindow.activeIsA) {
                            fadeAnimB.restart()
                            scaleAnimB.restart()
                            fadeAnimA_out.restart()
                            wallpaperBgWindow.activeIsA = false
                        }
                    }

                    NumberAnimation {
                        id: fadeAnimB
                        target: imgB
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 650
                        easing.type: Easing.InOutCubic
                    }

                    NumberAnimation {
                        id: scaleAnimB
                        target: imgB
                        property: "scale"
                        from: 1.05
                        to: 1.0
                        duration: 850
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: fadeAnimB_out
                        target: imgB
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: 650
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }
}
