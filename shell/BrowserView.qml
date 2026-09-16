import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: browserRoot
    color: "#181b20"

    signal closeRequested()

    property string currentUrl: "https://plasma-mobile.org"
    property string pageTitle: "KDE Plasma Mobile"
    property string pageBody: "Plasma Mobile is an open-source user interface for mobile devices. Running on top of Linux and Wayland, it provides a privacy-respecting and customizable experience powered by KDE technologies."
    property string pageStatus: "Loaded"
    property bool isLoading: false

    Component.onCompleted: {
        navigateUrl(browserRoot.currentUrl);
    }

    function navigateUrl(url) {
        browserRoot.isLoading = true;
        if (typeof systemBackend !== "undefined") {
            try {
                var res = JSON.parse(systemBackend.fetchWebPage(url));
                browserRoot.currentUrl = res.url;
                browserRoot.pageTitle = res.title;
                browserRoot.pageBody = res.snippet || "No text content available.";
                browserRoot.pageStatus = res.status;
            } catch (e) {
                browserRoot.pageTitle = "Error Loading Page";
                browserRoot.pageBody = e.toString();
                browserRoot.pageStatus = "Error";
            }
        }
        browserRoot.isLoading = false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header & Navigation Bar
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Button {
                    text: "⬅"
                    flat: true
                    implicitWidth: 32
                    onClicked: urlBar.text = "https://plasma-mobile.org"
                }

                TextField {
                    id: urlBar
                    Layout.fillWidth: true
                    text: browserRoot.currentUrl
                    placeholderText: "Search or enter URL..."
                    color: "#ffffff"
                    font.pixelSize: 12
                    onAccepted: browserRoot.navigateUrl(text.trim())
                }

                Button {
                    text: browserRoot.isLoading ? "⏳" : "Go"
                    highlighted: true
                    implicitWidth: 44
                    onClicked: browserRoot.navigateUrl(urlBar.text.trim())
                }

                Button {
                    text: "✕"
                    flat: true
                    implicitWidth: 32
                    onClicked: browserRoot.closeRequested()
                }
            }
        }

        // Quick Bookmark Shortcuts
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 6

                Repeater {
                    model: [
                        { name: "Plasma Mobile", url: "https://plasma-mobile.org" },
                        { name: "Arch Linux", url: "https://archlinux.org" },
                        { name: "Halium", url: "https://halium.org" },
                        { name: "Kernel.org", url: "https://kernel.org" }
                    ]
                    delegate: Button {
                        text: modelData.name
                        flat: true
                        implicitHeight: 26
                        onClicked: {
                            urlBar.text = modelData.url;
                            browserRoot.navigateUrl(modelData.url);
                        }
                    }
                }
            }
        }

        // Web Content Viewport Surface
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"

            ScrollView {
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 16
                    Layout.margins: 20

                    // URL Security Badge
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 6
                        color: browserRoot.currentUrl.startsWith("https://") ? "#e8f8f5" : "#fef9e7"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            Text {
                                text: browserRoot.currentUrl.startsWith("https://") ? "🔒 Secure Connection" : "⚠️ Insecure Connection"
                                font.pixelSize: 11
                                font.bold: true
                                color: browserRoot.currentUrl.startsWith("https://") ? "#16a085" : "#f39c12"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: browserRoot.pageStatus
                                font.pixelSize: 11
                                color: "#7f8c8d"
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: browserRoot.pageTitle
                        font.bold: true
                        font.pixelSize: 22
                        wrapMode: Text.WordWrap
                        color: "#2c3e50"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: "#3daee9"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: browserRoot.pageBody
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                        color: "#34495e"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        color: "#f8f9fa"
                        radius: 8

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "Angelfish Mobile Browser Engine"
                                font.bold: true
                                font.pixelSize: 12
                                color: "#7f8c8d"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Qt 6 / Wayland client • Nexus 6P (MSM8994)"
                                font.pixelSize: 10
                                color: "#bdc3c7"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
