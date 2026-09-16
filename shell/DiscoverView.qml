import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: discoverRoot
    color: "#181b20"

    signal closeRequested()

    property string activeTab: "Featured" // "Featured", "Installed", "Updates"

    ListModel {
        id: packagesModel
    }

    Component.onCompleted: {
        search("");
    }

    function search(query) {
        if (typeof systemBackend !== "undefined") {
            try {
                var list = JSON.parse(systemBackend.searchPackages(query));
                packagesModel.clear();
                for (var i = 0; i < list.length; i++) {
                    packagesModel.append({
                        name: list[i].name,
                        version: list[i].version,
                        repo: list[i].repo,
                        desc: list[i].desc,
                        installed: list[i].installed
                    });
                }
            } catch (e) {
                console.log("Error querying packages:", e);
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
                    text: "🛍 Discover Software Center"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: discoverRoot.closeRequested()
                }
            }
        }

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "🔍 Search apps and add-ons..."
                    color: "#ffffff"
                    onAccepted: discoverRoot.search(text.trim())
                }

                Button {
                    text: "Search"
                    highlighted: true
                    onClicked: discoverRoot.search(searchField.text.trim())
                }
            }
        }

        // Section Tabs
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#1c1f26"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 4

                Repeater {
                    model: ["Featured", "Installed", "Updates"]
                    delegate: Button {
                        text: modelData
                        flat: discoverRoot.activeTab !== modelData
                        highlighted: discoverRoot.activeTab === modelData
                        implicitHeight: 28
                        onClicked: discoverRoot.activeTab = modelData
                    }
                }
            }
        }

        // Package List
        ListView {
            id: packagesView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: packagesModel

            delegate: Rectangle {
                width: packagesView.width
                color: index % 2 === 0 ? "#1e2129" : "#232731"
                border.color: Qt.rgba(1, 1, 1, 0.04)

                visible: (discoverRoot.activeTab === "Featured") ||
                         (discoverRoot.activeTab === "Installed" && model.installed) ||
                         (discoverRoot.activeTab === "Updates" && !model.installed)
                height: visible ? 74 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 10
                        color: model.installed ? "#27ae60" : "#3daee9"

                        Text {
                            anchors.centerIn: parent
                            text: model.installed ? "✓" : "📦"
                            font.pixelSize: 20
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 8
                            Text {
                                text: model.name
                                font.bold: true
                                font.pixelSize: 14
                                color: "#ffffff"
                            }
                            Text {
                                text: "v" + model.version + " (" + model.repo + ")"
                                font.pixelSize: 11
                                color: "#3daee9"
                            }
                        }

                        Text {
                            text: model.desc
                            font.pixelSize: 12
                            color: "#a0a5ad"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        text: model.installed ? "Installed" : "Install"
                        flat: model.installed
                        highlighted: !model.installed
                        onClicked: {
                            if (!model.installed) {
                                model.installed = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
