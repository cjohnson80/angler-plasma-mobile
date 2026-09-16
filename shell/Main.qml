import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

ApplicationWindow {
    id: root
    visible: true
    width: 412
    height: 732
    title: "KDE Plasma 6 Mobile Shell (Nexus 6P / angler)"
    color: "#181b20"

    // Colors matching KDE Plasma 6 Breeze Dark
    readonly property color breezeDark: "#1f232a"
    readonly property color breezeSurface: "#2a2e38"
    readonly property color breezeAccent: "#3daee9"
    readonly property color breezeAccentActive: "#1d99f3"
    readonly property color breezeText: "#fcfcfc"
    readonly property color breezeTextDim: "#a0a5ad"
    readonly property color breezeCard: "#23262e"
    readonly property color breezeBorder: Qt.rgba(1, 1, 1, 0.08)

    // Shell state
    property bool quickSettingsOpen: false
    property bool appSwitcherOpen: false
    property bool appDrawerOpen: false
    property string activeApp: ""
    property real brightnessVal: 0.75
    property real volumeVal: 0.60

    // Running tasks model (for Task Switcher / Overview)
    ListModel {
        id: openTasksModel
        ListElement { name: "Terminal"; icon: "⌨"; color: "#232629"; summary: "chris@angler-plasma:~$ uname -r\n3.10.73-halium-angler" }
        ListElement { name: "Dolphin"; icon: "📁"; color: "#1d99f3"; summary: "Home > Documents\nStorage: 64 GB internal" }
        ListElement { name: "Angelfish"; icon: "🌐"; color: "#27ae60"; summary: "kde.org/plasma-mobile\nPlasma 6 on Wayland" }
        ListElement { name: "Settings"; icon: "⚙"; color: "#7f8c8d"; summary: "Nexus 6P (MSM8994)\nlibhybris hwcomposer" }
    }

    // Installed apps model (Full app list for Drawer)
    ListModel {
        id: allAppsModel
        ListElement { name: "Terminal"; icon: "⌨"; color: "#232629"; desc: "KDE Konsole mobile terminal" }
        ListElement { name: "Dolphin"; icon: "📁"; color: "#1d99f3"; desc: "Plasma file manager" }
        ListElement { name: "Angelfish"; icon: "🌐"; color: "#27ae60"; desc: "Touch-optimized web browser" }
        ListElement { name: "Settings"; icon: "⚙"; color: "#7f8c8d"; desc: "System hardware & network" }
        ListElement { name: "Dialer"; icon: "📞"; color: "#2ecc71"; desc: "Phone dialer & contacts" }
        ListElement { name: "Messages"; icon: "💬"; color: "#3498db"; desc: "SMS / MMS messaging" }
        ListElement { name: "Camera"; icon: "📷"; color: "#e67e22"; desc: "12.3 MP Sony IMX377" }
        ListElement { name: "Discover"; icon: "🛍"; color: "#9b59b6"; desc: "Software Center & Flatpaks" }
        ListElement { name: "Calculator"; icon: "🧮"; color: "#e74c3c"; desc: "KCalc mobile" }
        ListElement { name: "Clock"; icon: "⏰"; color: "#f39c12"; desc: "Alarms, timers & stopwatch" }
        ListElement { name: "Media"; icon: "🎵"; color: "#16a085"; desc: "Elisa music player" }
        ListElement { name: "Notes"; icon: "📝"; color: "#8e44ad"; desc: "Quick notes and memos" }
        ListElement { name: "Contacts"; icon: "👥"; color: "#2980b9"; desc: "Address book and phonebook" }
        ListElement { name: "Calendar"; icon: "📅"; color: "#e67e22"; desc: "Agenda and calendar events" }
        ListElement { name: "Tasks"; icon: "✓"; color: "#27ae60"; desc: "To-do lists and reminders" }
        ListElement { name: "Weather"; icon: "⛅"; color: "#3498db"; desc: "Forecast and atmospheric metrics" }
    }

    // Quick toggle states
    property var quickToggles: [
        { label: "Wi-Fi", icon: "📶", active: true },
        { label: "Cellular", icon: "📡", active: true },
        { label: "Bluetooth", icon: "ᛒ", active: false },
        { label: "Flashlight", icon: "🔦", active: false },
        { label: "Auto-Rotate", icon: "🔄", active: true },
        { label: "Night Light", icon: "🌙", active: true }
    ]

    function launchApp(appName) {
        // Add to tasks if not present
        var found = false;
        for (var i = 0; i < openTasksModel.count; i++) {
            if (openTasksModel.get(i).name === appName) {
                found = true;
                break;
            }
        }
        if (!found) {
            openTasksModel.append({
                name: appName,
                icon: "📱",
                color: root.breezeAccent,
                summary: "Active Plasma 6 Wayland Surface"
            });
        }
        root.activeApp = appName;
        root.appDrawerOpen = false;
        root.appSwitcherOpen = false;
        root.quickSettingsOpen = false;
    }

    function closeTask(index) {
        var name = openTasksModel.get(index).name;
        openTasksModel.remove(index);
        if (root.activeApp === name) {
            root.activeApp = "";
        }
        if (openTasksModel.count === 0) {
            root.appSwitcherOpen = false;
        }
    }

    // Background Wallpaper
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1b2a4a" }
            GradientStop { position: 0.4; color: "#141c2b" }
            GradientStop { position: 1.0; color: "#0d1117" }
        }

        Canvas {
            anchors.fill: parent
            opacity: 0.18
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#3daee9";
                ctx.beginPath();
                ctx.moveTo(width * 0.2, 0);
                ctx.lineTo(width, height * 0.4);
                ctx.lineTo(width, 0);
                ctx.closePath();
                ctx.fill();

                ctx.fillStyle = "#1d99f3";
                ctx.beginPath();
                ctx.moveTo(0, height * 0.7);
                ctx.lineTo(width * 0.8, height);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fill();
            }
        }
    }

    // Top Status Bar (Plasma 6 Mobile Panel)
    Rectangle {
        id: statusBar
        z: 30
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: root.quickSettingsOpen ? root.breezeDark : Qt.rgba(0.08, 0.09, 0.11, 0.75)

        Behavior on color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "hh:mm")
                font.pixelSize: 13
                font.bold: true
                color: root.breezeText
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 10
                Text { text: "LTE 4G"; font.pixelSize: 11; color: root.breezeTextDim }
                Text { text: "📶"; font.pixelSize: 11; color: root.breezeText }
                Text { text: "🔋 85%"; font.pixelSize: 11; font.bold: true; color: root.breezeAccent }
            }
        }

        // Tap or swipe down from top to toggle Quick Settings
        MouseArea {
            anchors.fill: parent
            property real startY: 0
            onPressed: (mouse) => startY = mouse.y
            onReleased: (mouse) => {
                if (mouse.y - startY > 15 || startY - mouse.y < 5) {
                    root.quickSettingsOpen = !root.quickSettingsOpen;
                    if (root.quickSettingsOpen) {
                        root.appDrawerOpen = false;
                        root.appSwitcherOpen = false;
                    }
                }
            }
        }
    }

    // Homescreen View
    Item {
        id: desktopArea
        anchors.top: statusBar.bottom
        anchors.bottom: navigationBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.activeApp === "" && !root.appSwitcherOpen && !root.appDrawerOpen

        // Digital Clock Widget (Plasma 6 Lock/Home Widget)
        ColumnLayout {
            anchors.top: parent.top
            anchors.topMargin: 36
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                font.pixelSize: 60
                font.weight: Font.Light
                color: root.breezeText
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                font.pixelSize: 15
                color: root.breezeAccent
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Nexus 6P • Halium 8.1 • Wayland"
                font.pixelSize: 11
                color: root.breezeTextDim
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
            }
        }

        // Homescreen Pinned Apps Grid (Favorites)
        GridLayout {
            anchors.bottom: swipeUpHint.top
            anchors.bottomMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 4
            rowSpacing: 22
            columnSpacing: 22

            Repeater {
                model: 8
                delegate: ColumnLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        width: 58
                        height: 58
                        radius: 18
                        color: allAppsModel.get(index).color
                        border.color: root.breezeBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: allAppsModel.get(index).icon
                            font.pixelSize: 26
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.launchApp(allAppsModel.get(index).name)
                        }
                    }

                    Text {
                        text: allAppsModel.get(index).name
                        font.pixelSize: 11
                        color: root.breezeText
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // App Drawer Swipe Up Handle / Indicator
        Rectangle {
            id: swipeUpHint
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: 140
            height: 28
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "▲"; font.pixelSize: 10; color: root.breezeTextDim }
                Text { text: "All Apps"; font.pixelSize: 11; font.bold: true; color: root.breezeTextDim }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.appDrawerOpen = true
            }
        }

        // Gesture detector on homescreen for swipe up to open App Drawer
        MouseArea {
            anchors.fill: parent
            anchors.bottomMargin: 50
            z: -1
            property real startY: 0
            onPressed: (mouse) => startY = mouse.y
            onReleased: (mouse) => {
                if (startY - mouse.y > 60) {
                    root.appDrawerOpen = true;
                }
            }
        }
    }

    // App Drawer (Full Application Grid with Search)
    Rectangle {
        id: appDrawerPanel
        z: 22
        anchors.top: statusBar.bottom
        anchors.bottom: navigationBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.appDrawerOpen
        color: root.breezeDark

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 12
                color: root.breezeSurface
                border.color: root.breezeBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text { text: "🔍"; font.pixelSize: 14; color: root.breezeTextDim }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: root.breezeText
                        font.pixelSize: 14
                        text: ""
                        Text {
                            anchors.fill: parent
                            text: searchInput.text === "" ? "Search installed apps..." : ""
                            color: root.breezeTextDim
                            font.pixelSize: 14
                            visible: !searchInput.activeFocus && searchInput.text === ""
                        }
                    }

                    Text {
                        text: "✕"
                        font.pixelSize: 14
                        color: root.breezeTextDim
                        visible: searchInput.text.length > 0
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            // Apps Grid
            GridView {
                id: appsGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 4
                cellHeight: 96
                clip: true
                model: allAppsModel

                delegate: ColumnLayout {
                    width: appsGrid.cellWidth
                    spacing: 6

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 54
                        height: 54
                        radius: 16
                        color: model.color
                        border.color: root.breezeBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: model.icon
                            font.pixelSize: 24
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.launchApp(model.name)
                        }
                    }

                    Text {
                        text: model.name
                        font.pixelSize: 11
                        color: root.breezeText
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // Task Switcher / Overview (Plasma 6 Carousel Switcher)
    Rectangle {
        id: appSwitcherPanel
        z: 25
        anchors.top: statusBar.bottom
        anchors.bottom: navigationBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.appSwitcherOpen
        color: Qt.rgba(0.09, 0.11, 0.14, 0.95)

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 20
            anchors.bottomMargin: 10
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24

                Text {
                    text: "Task Overview (" + openTasksModel.count + " running)"
                    font.bold: true
                    font.pixelSize: 16
                    color: root.breezeText
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Clear All"
                    flat: true
                    onClicked: {
                        openTasksModel.clear();
                        root.activeApp = "";
                        root.appSwitcherOpen = false;
                    }
                }
            }

            // Card Carousel of open apps
            ListView {
                id: tasksListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: 20
                clip: true
                model: openTasksModel
                preferredHighlightBegin: width / 2 - 130
                preferredHighlightEnd: width / 2 + 130
                highlightRangeMode: ListView.StrictlyEnforceRange

                delegate: Rectangle {
                    width: 260
                    height: tasksListView.height - 40
                    radius: 20
                    color: root.breezeSurface
                    border.color: root.breezeBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // Card Header
                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 8
                                color: model.color
                                Text {
                                    anchors.centerIn: parent
                                    text: model.icon
                                    font.pixelSize: 14
                                }
                            }
                            Text {
                                text: model.name
                                font.bold: true
                                font.pixelSize: 15
                                color: root.breezeText
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "✕"
                                flat: true
                                onClicked: root.closeTask(index)
                            }
                        }

                        // Preview Surface Placeholder
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: root.breezeCard

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 24
                                text: model.summary
                                font.family: "monospace"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                color: root.breezeTextDim
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Tap to switch
                        Button {
                            Layout.fillWidth: true
                            text: "Switch to " + model.name
                            highlighted: true
                            onClicked: {
                                root.activeApp = model.name;
                                root.appSwitcherOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // Plasma 6 Quick Settings Pull-Down Panel
    Rectangle {
        id: quickSettingsPanel
        z: 35
        anchors.top: statusBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.quickSettingsOpen ? 420 : 0
        clip: true
        color: root.breezeDark
        opacity: root.quickSettingsOpen ? 0.98 : 0.0

        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Text {
                text: "Quick Controls"
                font.bold: true
                font.pixelSize: 14
                color: root.breezeTextDim
            }

            // Quick Toggles Grid
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: root.quickToggles

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        color: modelData.active ? root.breezeAccent : root.breezeSurface
                        border.color: root.breezeBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: modelData.icon
                                font.pixelSize: 16
                            }

                            Text {
                                text: modelData.label
                                font.bold: true
                                font.pixelSize: 13
                                color: modelData.active ? "#ffffff" : root.breezeText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                modelData.active = !modelData.active;
                                quickSettingsPanel.update();
                            }
                        }
                    }
                }
            }

            // Brightness Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "☀️"; font.pixelSize: 14; color: root.breezeText }
                Slider {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    value: root.brightnessVal
                    onMoved: root.brightnessVal = value
                }
                Text { text: Math.round(root.brightnessVal * 100) + "%"; font.pixelSize: 12; color: root.breezeTextDim; Layout.preferredWidth: 35 }
            }

            // Volume Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "🔊"; font.pixelSize: 14; color: root.breezeText }
                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    value: root.volumeVal
                    onMoved: root.volumeVal = value
                }
                Text { text: Math.round(root.volumeVal * 100) + "%"; font.pixelSize: 12; color: root.breezeTextDim; Layout.preferredWidth: 35 }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Close"
                    onClicked: root.quickSettingsOpen = false
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Settings"
                    onClicked: {
                        root.quickSettingsOpen = false;
                        root.launchApp("Settings");
                    }
                }
            }
        }
    }

    // Active Application Surface (when an app is open)
    Rectangle {
        id: appWindow
        z: 20
        anchors.top: statusBar.bottom
        anchors.bottom: navigationBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.activeApp !== "" && !root.appSwitcherOpen
        color: root.breezeDark

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // App Header Bar
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: root.breezeSurface
                border.color: root.breezeBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Text {
                        text: root.activeApp
                        font.bold: true
                        font.pixelSize: 16
                        color: root.breezeText
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "✕"
                        flat: true
                        onClicked: root.activeApp = ""
                    }
                }
            }

            // App Content Surface
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Interactive Terminal Component
                TerminalView {
                    anchors.fill: parent
                    visible: root.activeApp === "Terminal"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Dolphin File Manager Component
                DolphinView {
                    anchors.fill: parent
                    visible: root.activeApp === "Dolphin"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive System Settings Component
                SettingsView {
                    anchors.fill: parent
                    visible: root.activeApp === "Settings"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Dialer Component
                DialerView {
                    anchors.fill: parent
                    visible: root.activeApp === "Dialer"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Camera Component
                CameraView {
                    anchors.fill: parent
                    visible: root.activeApp === "Camera"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Messages Component
                MessagesView {
                    anchors.fill: parent
                    visible: root.activeApp === "Messages"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Notes Component
                NotesView {
                    anchors.fill: parent
                    visible: root.activeApp === "Notes"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Clock & Timer Component
                ClockView {
                    anchors.fill: parent
                    visible: root.activeApp === "Clock"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Calculator Component
                CalcView {
                    anchors.fill: parent
                    visible: root.activeApp === "Calculator"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Elisa Media Player Component
                MediaView {
                    anchors.fill: parent
                    visible: root.activeApp === "Media"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Contacts PIM Component
                ContactsView {
                    anchors.fill: parent
                    visible: root.activeApp === "Contacts"
                    onCloseRequested: root.activeApp = ""
                    onContactSelected: (name, phone) => {
                        root.launchApp("Dialer");
                    }
                }

                // Interactive Calendar PIM Component
                CalendarView {
                    anchors.fill: parent
                    visible: root.activeApp === "Calendar"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Tasks PIM Component
                TasksView {
                    anchors.fill: parent
                    visible: root.activeApp === "Tasks"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Weather Component
                WeatherView {
                    anchors.fill: parent
                    visible: root.activeApp === "Weather"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Angelfish Web Browser Component
                BrowserView {
                    anchors.fill: parent
                    visible: root.activeApp === "Angelfish"
                    onCloseRequested: root.activeApp = ""
                }

                // Interactive Discover Software Center Component
                DiscoverView {
                    anchors.fill: parent
                    visible: root.activeApp === "Discover"
                    onCloseRequested: root.activeApp = ""
                }

                // Generic Fallback View for Other Apps
                Rectangle {
                    anchors.fill: parent
                    visible: root.activeApp !== "" && root.activeApp !== "Terminal" && root.activeApp !== "Dolphin" && root.activeApp !== "Settings" && root.activeApp !== "Dialer" && root.activeApp !== "Camera" && root.activeApp !== "Messages" && root.activeApp !== "Notes" && root.activeApp !== "Clock" && root.activeApp !== "Calculator" && root.activeApp !== "Media" && root.activeApp !== "Contacts" && root.activeApp !== "Calendar" && root.activeApp !== "Tasks" && root.activeApp !== "Weather" && root.activeApp !== "Angelfish" && root.activeApp !== "Discover"
                    color: root.breezeDark

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 14

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 72
                            height: 72
                            radius: 20
                            color: root.breezeAccentActive

                            Text {
                                anchors.centerIn: parent
                                text: "📱"
                                font.pixelSize: 36
                            }
                        }

                        Text {
                            text: root.activeApp
                            font.pixelSize: 22
                            font.bold: true
                            color: root.breezeText
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "KDE Plasma 6 Mobile Surface\nWayland Client • libhybris EGL"
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 13
                            color: root.breezeTextDim
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Switch App (Overview)"
                            onClicked: root.appSwitcherOpen = true
                        }
                    }
                }
            }
        }
    }

    // Bottom Navigation Bar (Plasma 6 Mobile Task Navigation)
    Rectangle {
        id: navigationBar
        z: 30
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 54
        color: root.breezeDark
        border.color: root.breezeBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40

            // Back button
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    anchors.centerIn: parent
                    text: "◀"
                    font.pixelSize: 18
                    color: root.breezeText
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.quickSettingsOpen) root.quickSettingsOpen = false;
                        else if (root.appSwitcherOpen) root.appSwitcherOpen = false;
                        else if (root.appDrawerOpen) root.appDrawerOpen = false;
                        else if (root.activeApp !== "") root.activeApp = "";
                    }
                }
            }

            // Home button
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: root.breezeText
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.activeApp = "";
                        root.appSwitcherOpen = false;
                        root.appDrawerOpen = false;
                        root.quickSettingsOpen = false;
                    }
                }
            }

            // Task Overview / Switcher button
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 3
                    color: root.appSwitcherOpen ? root.breezeAccent : "transparent"
                    border.color: root.breezeText
                    border.width: 2
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.appSwitcherOpen = !root.appSwitcherOpen;
                        if (root.appSwitcherOpen) {
                            root.appDrawerOpen = false;
                            root.quickSettingsOpen = false;
                        }
                    }
                }
            }
        }
    }
}
