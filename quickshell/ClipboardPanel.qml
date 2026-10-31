import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// Clipboard history (cliphist) — same look as AppLauncher
PanelWindow {
    id: clipboardWindow

    property bool isOpen: false

    property var barWindowRef: null // bar clicks pass through the focus grab

    screen: barWindowRef ? barWindowRef.screen : null // open on the bar's screen

    function toggle() { isOpen = !isOpen }
    function open() { isOpen = true }
    function close() { isOpen = false }

    // Theme properties matching AppLauncher
    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color bgColor3: "#262626"
    property color fgColor: "#CDD6F4"
    property color accentColor: "#89B4FA"
    property string mainFont: "Rowdies"

    // ─── Global Shortcut & IPC Handler ────────────────────────
    GlobalShortcut {
        name: "clipboard"
        description: "Toggle Quickshell Clipboard History"
        onPressed: clipboardWindow.toggle()
    }

    IpcHandler {
        target: "clipboard"
        function toggle() { clipboardWindow.toggle() }
        function open() { clipboardWindow.open() }
        function close() { clipboardWindow.close() }
    }

    // ─── History Data & Search Model ──────────────────────────
    property var allItems: []
    property string searchText: ""
    property int selectedIndex: 0
    property bool cliphistMissing: false

    // Wrapped in sh so a missing cliphist binary gives exit code 127
    Process {
        id: listProc
        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 127; cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                let lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let raw = lines[i]
                    let tab = raw.indexOf("\t")
                    if (tab < 0) continue
                    let preview = raw.substring(tab + 1)
                    let isImage = preview.startsWith("[[ binary data")
                    list.push({
                        raw: raw,
                        id: raw.substring(0, tab),
                        preview: isImage ? preview.replace("[[ binary data", "Image").replace(" ]]", "") : preview,
                        isImage: isImage
                    })
                }
                clipboardWindow.allItems = list
            }
        }
        onExited: (exitCode) => {
            // 127 = command not found
            clipboardWindow.cliphistMissing = (exitCode === 127)
        }
    }

    function refresh() {
        listProc.running = true
    }

    Process { id: actionProc }

    readonly property var filteredItems: {
        let q = searchText.trim().toLowerCase()
        if (q === "") return allItems
        return allItems.filter(item => item.preview.toLowerCase().includes(q))
    }

    onSearchTextChanged: {
        selectedIndex = 0
        if (clipList) clipList.positionViewAtBeginning()
    }

    function copyItem(index) {
        if (index < 0 || index >= filteredItems.length) return
        actionProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", filteredItems[index].id]
        actionProc.running = true
        close()
    }

    function deleteItem(index) {
        if (index < 0 || index >= filteredItems.length) return
        let raw = filteredItems[index].raw
        allItems = allItems.filter(item => item.raw !== raw)
        if (selectedIndex >= filteredItems.length) selectedIndex = Math.max(0, filteredItems.length - 1)
        actionProc.command = ["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", raw]
        actionProc.running = true
    }

    function clearAll() {
        allItems = []
        actionProc.command = ["cliphist", "wipe"]
        actionProc.running = true
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchText = ""
            selectedIndex = 0
            refresh()
            if (searchInput) {
                searchInput.text = ""
                focusTimer.restart()
            }
            dropUpAnim.stop()
            panelRootItem.opacity = 1.0
            dropDownAnim.restart()
        } else {
            dropDownAnim.stop()
            dropUpAnim.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: if (searchInput) searchInput.forceActiveFocus()
    }

    // ─── Window Configuration ─────────────────────────────────
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Close on a click anywhere outside the panel, including the other monitor
    // (Exclusive keyboard focus made Hyprland swallow those clicks instead)
    HyprlandFocusGrab {
        windows: clipboardWindow.barWindowRef ? [ clipboardWindow, clipboardWindow.barWindowRef ] : [ clipboardWindow ]
        active: clipboardWindow.isOpen
        onCleared: clipboardWindow.close()
    }

    visible: isOpen || dropDownAnim.running || dropUpAnim.running

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: clipboardWindow.close()
    }

    // ─── THE PANEL ROOT ITEM ──────────────────────────────────
    Item {
        id: panelRootItem
        width: cardContainer.width
        height: cardContainer.height
        x: Math.round((parent.width - width) / 2)
        y: -cardContainer.height
        opacity: 0.0

        NumberAnimation {
            id: dropDownAnim
            target: panelRootItem
            property: "y"
            from: -cardContainer.height
            to: 8 // gap under the bar
            duration: 280
            easing.type: Easing.OutCubic
        }

        ParallelAnimation {
            id: dropUpAnim
            NumberAnimation {
                target: panelRootItem
                property: "y"
                to: -cardContainer.height
                duration: 240
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: panelRootItem
                property: "opacity"
                to: 0.0
                duration: 200
                easing.type: Easing.InQuad
            }
        }

        // Left curved fillet joining the card smoothly into the top bar
        Shape {
            visible: false // floating card, no bar fillet
            width: 16
            height: 16
            transform: Scale { origin.y: 8; yScale: -1 }
            anchors {
                right: cardContainer.left
                top: cardContainer.top
            }
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                fillColor: clipboardWindow.bgColor
                startX: 16
                startY: 0
                PathLine { x: 16; y: 16 }
                PathLine { x: 0; y: 16 }
                PathCubic {
                    x: 16
                    y: 0
                    control1X: 8.836
                    control1Y: 16
                    control2X: 16
                    control2Y: 8.836
                }
            }
        }

        // Right curved fillet joining the card smoothly into the top bar
        Shape {
            visible: false // floating card, no bar fillet
            width: 16
            height: 16
            transform: Scale { origin.y: 8; yScale: -1 }
            anchors {
                left: cardContainer.right
                top: cardContainer.top
            }
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                fillColor: clipboardWindow.bgColor
                startX: 0
                startY: 0
                PathLine { x: 0; y: 16 }
                PathLine { x: 16; y: 16 }
                PathCubic {
                    x: 0
                    y: 0
                    control1X: 7.164
                    control1Y: 16
                    control2X: 0
                    control2Y: 8.836
                }
            }
        }

        // ─── CARD CONTAINER ───────────────────────────────────
        Rectangle {
            id: cardContainer
            width: 560
            height: 500
            topLeftRadius: bottomLeftRadius
            topRightRadius: bottomRightRadius
            bottomLeftRadius: 24
            bottomRightRadius: 24
            color: clipboardWindow.bgColor

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.55
                shadowBlur: 0.5
                shadowVerticalOffset: 4
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {} // Block clicks through to backdrop
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 16
                    bottomMargin: 16
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 12

                // ─── 1. Header Row (Title, Count Badge, Clear, Close) ─
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 8

                    Text {
                        text: "Clipboard"
                        font { family: clipboardWindow.mainFont; pixelSize: 16 }
                        color: "#FFFFFF"
                    }

                    Rectangle {
                        implicitWidth: countText.implicitWidth + 14
                        implicitHeight: 20
                        radius: 10
                        color: clipboardWindow.bgColor2

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: clipboardWindow.searchText.trim() === "" ? (clipboardWindow.allItems.length + " items") : (clipboardWindow.filteredItems.length + " found")
                            font { family: "Inter"; pixelSize: 10; weight: Font.Bold }
                            color: clipboardWindow.accentColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Clear All Button
                    Rectangle {
                        visible: clipboardWindow.allItems.length > 0
                        implicitWidth: clearAllText.implicitWidth + 16
                        implicitHeight: 26
                        radius: 13
                        color: clearAllArea.containsMouse ? Qt.lighter(clipboardWindow.bgColor2, 1.4) : clipboardWindow.bgColor2

                        Text {
                            id: clearAllText
                            anchors.centerIn: parent
                            text: "Clear all"
                            font { family: "Inter"; pixelSize: 10; weight: Font.Bold }
                            color: clearAllArea.containsMouse ? "#F38BA8" : clipboardWindow.fgColor
                        }

                        MouseArea {
                            id: clearAllArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipboardWindow.clearAll()
                        }
                    }

                    // Close Button
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: closeBtnArea.containsMouse ? Qt.lighter(clipboardWindow.bgColor2, 1.4) : clipboardWindow.bgColor2

                        Text {
                            anchors.centerIn: parent
                            text: "" // times
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                            color: closeBtnArea.containsMouse ? "#FFFFFF" : clipboardWindow.fgColor
                        }

                        MouseArea {
                            id: closeBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipboardWindow.close()
                        }
                    }
                }

                // ─── 2. Search Bar ────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: clipboardWindow.bgColor2
                    border.width: 1
                    border.color: searchInput.activeFocus ? clipboardWindow.accentColor : "#2C2C30"

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 12
                        }
                        spacing: 10

                        Text {
                            text: ""
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 13 }
                            color: searchInput.activeFocus ? clipboardWindow.accentColor : clipboardWindow.fgColor
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font { family: "Inter"; pixelSize: 13; weight: Font.Medium }
                            color: "#FFFFFF"
                            selectionColor: clipboardWindow.accentColor
                            selectedTextColor: clipboardWindow.bgColor
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Type to search clipboard..."
                                font: parent.font
                                color: "#71717A"
                                visible: !parent.text && !parent.activeFocus
                            }

                            onTextChanged: clipboardWindow.searchText = text

                            Keys.onDownPressed: (event) => {
                                event.accepted = true
                                if (clipboardWindow.selectedIndex < clipboardWindow.filteredItems.length - 1) {
                                    clipboardWindow.selectedIndex++
                                    clipList.positionViewAtIndex(clipboardWindow.selectedIndex, ListView.Contain)
                                }
                            }

                            Keys.onUpPressed: (event) => {
                                event.accepted = true
                                if (clipboardWindow.selectedIndex > 0) {
                                    clipboardWindow.selectedIndex--
                                    clipList.positionViewAtIndex(clipboardWindow.selectedIndex, ListView.Contain)
                                }
                            }

                            Keys.onReturnPressed: (event) => {
                                event.accepted = true
                                clipboardWindow.copyItem(clipboardWindow.selectedIndex)
                            }

                            Keys.onEnterPressed: (event) => {
                                event.accepted = true
                                clipboardWindow.copyItem(clipboardWindow.selectedIndex)
                            }

                            Keys.onEscapePressed: (event) => {
                                event.accepted = true
                                clipboardWindow.close()
                            }

                            // Shift+Delete removes the selected entry
                            Keys.onDeletePressed: (event) => {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    event.accepted = true
                                    clipboardWindow.deleteItem(clipboardWindow.selectedIndex)
                                }
                            }
                        }
                    }
                }

                // ─── 3. History List ──────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty State
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: clipboardWindow.filteredItems.length === 0
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "" // clipboard
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 34 }
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: clipboardWindow.cliphistMissing ? "cliphist is not installed" : (clipboardWindow.searchText.trim() === "" ? "Clipboard is empty" : "Nothing Found")
                            font { family: clipboardWindow.mainFont; pixelSize: 15 }
                            color: "#FFFFFF"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: clipboardWindow.cliphistMissing ? "Run: sudo pacman -S cliphist" : "Copy something and it will show up here"
                            font { family: "Inter"; pixelSize: 12 }
                            color: "#71717A"
                        }
                    }

                    ListView {
                        id: clipList
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        visible: clipboardWindow.filteredItems.length > 0
                        model: clipboardWindow.filteredItems
                        currentIndex: clipboardWindow.selectedIndex

                        delegate: Rectangle {
                            id: clipItem
                            width: clipList.width
                            height: 52
                            radius: 12
                            readonly property bool isSelected: index === clipboardWindow.selectedIndex

                            color: isSelected ? clipboardWindow.bgColor3 : (itemMouseArea.containsMouse ? Qt.lighter(clipboardWindow.bgColor2, 1.25) : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: isSelected ? Qt.rgba(242/255, 229/255, 188/255, 0.35) : "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: clipboardWindow.selectedIndex = index
                                onClicked: clipboardWindow.copyItem(index)
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: 12

                                // Type Icon
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: clipboardWindow.bgColor2

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.isImage ? "" : "" // image / file-lines
                                        font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 15 }
                                        color: clipboardWindow.accentColor
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.preview
                                    font { family: "Inter"; pixelSize: 13; weight: Font.Medium }
                                    color: isSelected ? clipboardWindow.accentColor : "#FFFFFF"
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    textFormat: Text.PlainText
                                }

                                // Delete Button (visible when selected)
                                Rectangle {
                                    visible: isSelected
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 8
                                    color: deleteArea.containsMouse ? Qt.lighter(clipboardWindow.bgColor2, 1.4) : clipboardWindow.bgColor2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "" // trash
                                        font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                                        color: deleteArea.containsMouse ? "#F38BA8" : clipboardWindow.fgColor
                                    }

                                    MouseArea {
                                        id: deleteArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clipboardWindow.deleteItem(index)
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── 4. Footer Row ────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    spacing: 8

                    Text {
                        text: "↑↓ Navigate"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }

                    Text {
                        text: "•"
                        font { family: "Inter"; pixelSize: 10 }
                        color: "#3F3F46"
                    }

                    Text {
                        text: "↵ Copy"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }

                    Text {
                        text: "•"
                        font { family: "Inter"; pixelSize: 10 }
                        color: "#3F3F46"
                    }

                    Text {
                        text: "⇧Del Remove"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: escText.implicitWidth + 8
                        implicitHeight: 16
                        radius: 4
                        color: clipboardWindow.bgColor2

                        Text {
                            id: escText
                            anchors.centerIn: parent
                            text: "ESC"
                            font { family: "Inter"; pixelSize: 9; weight: Font.Bold }
                            color: "#71717A"
                        }
                    }

                    Text {
                        text: "Close"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }
                }
            }
        }
    }
}
