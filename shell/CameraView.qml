import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: cameraRoot
    color: "#0a0c10"

    signal closeRequested()

    property bool isRecording: false
    property string activeCamera: "Rear (12.3 MP Sony IMX377)"
    property real zoomLevel: 1.0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header Controls
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: Qt.rgba(0, 0, 0, 0.6)
            z: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Text {
                    text: cameraRoot.activeCamera
                    font.bold: true
                    font.pixelSize: 13
                    color: "#ffffff"
                    Layout.fillWidth: true
                }

                Button {
                    text: "Flip 🔄"
                    flat: true
                    onClicked: {
                        if (cameraRoot.activeCamera.startsWith("Rear")) {
                            cameraRoot.activeCamera = "Front (8.0 MP Sony IMX179)";
                        } else {
                            cameraRoot.activeCamera = "Rear (12.3 MP Sony IMX377)";
                        }
                    }
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: cameraRoot.closeRequested()
                }
            }
        }

        // Viewfinder Surface Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#12141a"
            clip: true

            // Grid / Focus reticle
            Rectangle {
                anchors.centerIn: parent
                width: 120
                height: 120
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.3)
                border.width: 1
                radius: 4

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: "#3daee9"
                }
            }

            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    text: "Laser Autofocus • f/2.0 • 1.55 µm pixels"
                    font.pixelSize: 12
                    color: "#a0a5ad"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Qualcomm Spectra ISP • Halium Camera HAL"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.4)
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Bottom Capture Controls Bar
        Rectangle {
            Layout.fillWidth: true
            height: 90
            color: "#181b20"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 30

                // Gallery preview thumbnail
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: "#2a2e38"
                    border.color: Qt.rgba(1, 1, 1, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: "🖼"
                        font.pixelSize: 20
                    }
                }

                Item { Layout.fillWidth: true }

                // Shutter Button
                Rectangle {
                    width: 68
                    height: 68
                    radius: 34
                    color: "#ffffff"
                    border.color: "#3daee9"
                    border.width: 4

                    Rectangle {
                        anchors.centerIn: parent
                        width: 52
                        height: 52
                        radius: 26
                        color: cameraRoot.isRecording ? "#e74c3c" : "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            flashAnim.restart();
                            if (typeof systemBackend !== "undefined") {
                                var res = JSON.parse(systemBackend.capturePhoto(cameraRoot.activeCamera));
                                if (res.success) {
                                    console.log("Photo captured:", res.path);
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Mode Toggle (Photo / Video)
                Button {
                    text: cameraRoot.isRecording ? "Stop" : "Mode"
                    flat: true
                    onClicked: cameraRoot.isRecording = !cameraRoot.isRecording
                }
            }
        }
    }

    // Capture flash animation effect
    Rectangle {
        id: flashEffect
        anchors.fill: parent
        color: "#ffffff"
        opacity: 0.0

        SequentialAnimation {
            id: flashAnim
            NumberAnimation { target: flashEffect; property: "opacity"; to: 0.8; duration: 60 }
            NumberAnimation { target: flashEffect; property: "opacity"; to: 0.0; duration: 180 }
        }
    }
}
