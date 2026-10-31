//@ pragma UseQApplication
// shell.qml
import Quickshell
import QtQuick

Scope {
    WallpaperBackground {}

    Bar {
        id: mainBar
    }

    Rounded {}
    Overlay {
        accentColor: mainBar.accentColor
        isPanelOpen: mainBar.showControlPanel || mainBar.showFullPlayer || mainBar.showNotificationPanel || mainBar.showCalendar || mainBar.showAppLauncher || mainBar.showPowerMenu || mainBar.showWallpaperSelector
    }
    ScreenSharePicker {
        accentColor: mainBar.accentColor
    }
    ClipboardPanel {
        accentColor: mainBar.accentColor
        barWindowRef: mainBar.barPanelWindow
    }
}