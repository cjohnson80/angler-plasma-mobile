import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: dolphinView
    color: "#181b20"

    signal closeRequested()

    property string currentPath: "/home/chris"

    ListModel {
        id: fileModel
        ListElement { name: ".."; isDir: true; size: ""; icon: "↩" }
        ListElement { name: "Documents"; isDir: true; size: "4 items"; icon: "📁" }
        ListElement { name: "Downloads"; isDir: true; size: "12 items"; icon: "📁" }
        ListElement { name: "Pictures"; isDir: true; size: "48 items"; icon: "📁" }
        ListElement { name: "Projects"; isDir: true; size: "6 items"; icon: "📁" }
        ListElement { name: "angler-halium.log"; isDir: false; size: "14.2 KB"; icon: "📄" }
        ListElement { name: "plasma-session.sh"; isDir: false; size: "1.1 KB"; icon: "⚙" }
        ListElement { name: "wallpaper.png"; isDir: false; size: "2.8 MB"; icon: "🖼" }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Dolphin Header
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12

                Text {
                    text: "📁 Dolphin: " + dolphinView.currentPath
                    font.bold: true
                    font.pixelSize: 13
                    color: "#fcfcfc"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: dolphinView.closeRequested()
                }
            }
        }

        // Quick Places Breadcrumbs
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 8

                Repeater {
                    model: ["Root (/)", "Home", "Shared", "USB OTG"]
                    delegate: Button {
                        text: modelData
                        flat: true
                        implicitHeight: 26
                        onClicked: {
                            if (modelData === "Root (/)") dolphinView.currentPath = "/";
                            else if (modelData === "Home") dolphinView.currentPath = "/home/chris";
                            else if (modelData === "Shared") dolphinView.currentPath = "/data/media/0/NativOS";
                            else dolphinView.currentPath = "/mnt/media_rw";
                        }
                    }
                }
            }
        }

        // File List
        ListView {
            id: fileListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: fileModel

            delegate: Rectangle {
                width: fileListView.width
                height: 52
                color: index % 2 === 0 ? "#181b20" : "#1a1d24"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Text {
                        text: model.icon
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: model.name
                            font.bold: model.isDir
                            font.pixelSize: 14
                            color: "#ffffff"
                        }
                        Text {
                            text: model.size
                            font.pixelSize: 11
                            color: "#a0a5ad"
                            visible: model.size !== ""
                        }
                    }

                    Text {
                        text: model.isDir ? "›" : ""
                        font.pixelSize: 18
                        color: "#a0a5ad"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (model.isDir) {
                            if (model.name === "..") {
                                dolphinView.currentPath = "/home";
                            } else {
                                dolphinView.currentPath = dolphinView.currentPath + "/" + model.name;
                            }
                        }
                    }
                }
            }
        }
    }
}
