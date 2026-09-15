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
    readonly property color breezeText: "#fcfcfc"
    readonly property color breezeTextDim: "#a0a5ad"
    readonly property color breezeCard: "#23262e"

    property bool quickSettingsOpen: false
    property bool appDrawerOpen: false
    property string activeApp: ""

    // Background Wallpaper
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1b2a4a" }
            GradientStop { position: 0.4; color: "#141c2b" }
            GradientStop { position: 1.0; color: "#0d1117" }
        }

        // Geometric decorative accents reminiscent of KDE Plasma 6 wallpaper
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
        z: 20
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34
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

            // Status indicators (WiFi, Battery, Bluetooth, Halium status)
            RowLayout {
                spacing: 10

                Text {
                    text: "WiFi 5G"
                    font.pixelSize: 11
                    color: root.breezeTextDim
                }
                Text {
                    text: "85%"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.breezeAccent
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.quickSettingsOpen = !root.quickSettingsOpen;
                if (root.quickSettingsOpen) root.appDrawerOpen = false;
            }
        }
    }

    // Main Desktop / Homescreen Area
    Item {
        id: desktopArea
        anchors.top: statusBar.bottom
        anchors.bottom: navigationBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        // Digital Clock Widget (Plasma 6 Lock/Home Widget)
        ColumnLayout {
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                font.pixelSize: 56
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
                text: "Nexus 6P • Snapdragon 810 • Plasma 6"
                font.pixelSize: 11
                color: root.breezeTextDim
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
            }
        }

        // Homescreen Pinned Apps Grid
        GridLayout {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 4
            rowSpacing: 24
            columnSpacing: 22

            Repeater {
                model: [
                    { name: "Terminal", icon: "⌨", color: "#232629" },
                    { name: "Dolphin", icon: "📁", color: "#1d99f3" },
                    { name: "Angelfish", icon: "🌐", color: "#27ae60" },
                    { name: "Settings", icon: "⚙", color: "#7f8c8d" },
                    { name: "Dialer", icon: "📞", color: "#2ecc71" },
                    { name: "Messages", icon: "💬", color: "#3498db" },
                    { name: "Camera", icon: "📷", color: "#e67e22" },
                    { name: "Discover", icon: "🛍", color: "#9b59b6" }
                ]

                delegate: ColumnLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        width: 58
                        height: 58
                        radius: 18
                        color: modelData.color
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 26
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Launching: " + modelData.name);
                                root.activeApp = modelData.name;
                            }
                        }
                    }

                    Text {
                        text: modelData.name
                        font.pixelSize: 11
                        color: root.breezeText
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // Plasma 6 Quick Settings Pull-Down Panel
    Rectangle {
        id: quickSettingsPanel
        z: 30
        anchors.top: statusBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.quickSettingsOpen ? 340 : 0
        clip: true
        color: root.breezeDark
        opacity: root.quickSettingsOpen ? 0.98 : 0.0

        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            Text {
                text: "Plasma Quick Toggles"
                font.bold: true
                font.pixelSize: 14
                color: root.breezeTextDim
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        { label: "Wi-Fi", active: true },
                        { label: "Cellular", active: true },
                        { label: "Bluetooth", active: false },
                        { label: "Flashlight", active: false },
                        { label: "Rotation Lock", active: true },
                        { label: "Night Light", active: true }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        color: modelData.active ? root.breezeAccent : root.breezeSurface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14

                            Text {
                                text: modelData.label
                                font.bold: true
                                font.pixelSize: 13
                                color: modelData.active ? "#ffffff" : root.breezeText
                            }
                        }
                    }
                }
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
                    text: "System Settings"
                    onClicked: {
                        root.quickSettingsOpen = false;
                        root.activeApp = "Settings";
                    }
                }
            }
        }
    }

    // Application Mock Window (when an app is opened)
    Rectangle {
        id: appWindow
        z: 15
        anchors.top: statusBar.bottom
        anchors.bottom: navigationBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.activeApp !== ""
        color: root.breezeDark

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // App Header
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: root.breezeSurface

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

            // App Content Placeholder
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: root.breezeDark

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "Running: " + root.activeApp
                        font.pixelSize: 18
                        font.bold: true
                        color: root.breezeAccent
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "KDE Plasma 6 Mobile App Surface\nWayland / libhybris Client"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 13
                        color: root.breezeTextDim
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // Bottom Navigation Bar (Plasma Mobile Task Navigation)
    Rectangle {
        id: navigationBar
        z: 20
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        color: root.breezeDark

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
                        if (root.activeApp !== "") root.activeApp = "";
                        else if (root.quickSettingsOpen) root.quickSettingsOpen = false;
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
                        root.quickSettingsOpen = false;
                    }
                }
            }

            // Overview / App Switcher button
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 3
                    color: "transparent"
                    border.color: root.breezeText
                    border.width: 2
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Toggle task switcher");
                    }
                }
            }
        }
    }
}
