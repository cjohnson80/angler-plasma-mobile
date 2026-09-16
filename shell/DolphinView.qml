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
    }

    Component.onCompleted: refreshFiles()

    function refreshFiles() {
        fileModel.clear();
        if (typeof systemBackend !== "undefined") {
            var raw = systemBackend.listDirectory(dolphinView.currentPath);
            try {
                var data = JSON.parse(raw);
                dolphinView.currentPath = data.path;
                for (var i = 0; i < data.items.length; i++) {
                    fileModel.append(data.items[i]);
                }
            } catch (e) {
                console.log("Error parsing dolphin json: " + e);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
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
                    text: "🔄"
                    flat: true
                    onClicked: dolphinView.refreshFiles()
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
            height: 38
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 8

                Button {
                    text: "⬆ Up"
                    flat: true
                    implicitHeight: 28
                    onClicked: {
                        var parts = dolphinView.currentPath.split("/");
                        parts.pop();
                        var parentPath = parts.join("/");
                        if (parentPath === "") parentPath = "/";
                        dolphinView.currentPath = parentPath;
                        dolphinView.refreshFiles();
                    }
                }

                Repeater {
                    model: ["Root (/)", "Home", "Projects", "Tmp"]
                    delegate: Button {
                        text: modelData
                        flat: true
                        implicitHeight: 28
                        onClicked: {
                            if (modelData === "Root (/)") dolphinView.currentPath = "/";
                            else if (modelData === "Home") dolphinView.currentPath = "/home/chris";
                            else if (modelData === "Projects") dolphinView.currentPath = "/home/chris/Projects";
                            else if (modelData === "Tmp") dolphinView.currentPath = "/tmp";
                            dolphinView.refreshFiles();
                        }
                    }
                }
            }
        }

        // Real Live Filesystem List
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
                            elide: Text.ElideRight
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
                            dolphinView.currentPath = model.fullPath;
                            dolphinView.refreshFiles();
                        }
                    }
                }
            }
        }
    }
}
