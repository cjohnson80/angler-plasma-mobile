import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: dialerRoot
    color: "#181b20"

    signal closeRequested()

    property string dialedNumber: ""
    property string callStatus: "idle" // "idle", "calling", "connected"
    property int callSeconds: 0

    Timer {
        id: callTimer
        interval: 1000
        repeat: true
        running: dialerRoot.callStatus === "connected"
        onTriggered: dialerRoot.callSeconds++
    }

    function formatCallTime(secs) {
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
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
                    text: "📞 Phone"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: {
                        dialerRoot.callStatus = "idle";
                        dialerRoot.closeRequested();
                    }
                }
            }
        }

        // Active Call Overlay View
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#16191f"
            visible: dialerRoot.callStatus !== "idle"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 18

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 80
                    height: 80
                    radius: 40
                    color: "#2a2e38"

                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 42
                    }
                }

                Text {
                    text: dialerRoot.dialedNumber === "" ? "Unknown" : dialerRoot.dialedNumber
                    font.pixelSize: 26
                    font.bold: true
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: dialerRoot.callStatus === "calling" ? "Calling via Qualcomm MDM9635M..." : "Connected • " + dialerRoot.formatCallTime(dialerRoot.callSeconds)
                    font.pixelSize: 13
                    color: dialerRoot.callStatus === "calling" ? "#3daee9" : "#2ecc71"
                    Layout.alignment: Qt.AlignHCenter
                }

                // In-Call Controls
                RowLayout {
                    spacing: 20
                    Layout.topMargin: 24

                    Button {
                        text: "Mute"
                        flat: true
                    }
                    Button {
                        text: "Speaker"
                        flat: true
                    }
                    Button {
                        text: "Keypad"
                        flat: true
                    }
                }

                // End Call Button
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    width: 64
                    height: 64
                    radius: 32
                    color: "#e74c3c"

                    Text {
                        anchors.centerIn: parent
                        text: "📴"
                        font.pixelSize: 28
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            dialerRoot.callStatus = "idle";
                            dialerRoot.callSeconds = 0;
                        }
                    }
                }
            }
        }

        // Standard Dialpad View
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: dialerRoot.callStatus === "idle"
            spacing: 0

            // Number Display Area
            Rectangle {
                Layout.fillWidth: true
                height: 90
                color: "#181b20"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: dialerRoot.dialedNumber === "" ? "Enter a number" : dialerRoot.dialedNumber
                        font.pixelSize: 32
                        font.bold: true
                        color: dialerRoot.dialedNumber === "" ? "#7f8c8d" : "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Qualcomm Snapdragon 810 Modem RIL"
                        font.pixelSize: 11
                        color: "#a0a5ad"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Dialpad Keypad Grid
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.margins: 18
                columns: 3
                rowSpacing: 14
                columnSpacing: 18

                Repeater {
                    model: [
                        { digit: "1", sub: "" },
                        { digit: "2", sub: "ABC" },
                        { digit: "3", sub: "DEF" },
                        { digit: "4", sub: "GHI" },
                        { digit: "5", sub: "JKL" },
                        { digit: "6", sub: "MNO" },
                        { digit: "7", sub: "PQRS" },
                        { digit: "8", sub: "TUV" },
                        { digit: "9", sub: "WXYZ" },
                        { digit: "*", sub: "" },
                        { digit: "0", sub: "+" },
                        { digit: "#", sub: "" }
                    ]

                    delegate: Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 72
                        height: 72
                        radius: 36
                        color: "#23262e"
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: modelData.digit
                                font.pixelSize: 24
                                font.bold: true
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modelData.sub
                                font.pixelSize: 9
                                color: "#a0a5ad"
                                visible: modelData.sub !== ""
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: dialerRoot.dialedNumber += modelData.digit
                        }
                    }
                }
            }

            // Bottom Call & Delete Action Row
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 40
                Layout.rightMargin: 40
                Layout.bottomMargin: 16

                Item { Layout.fillWidth: true }

                // Call Button
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: "#2ecc71"

                    Text {
                        anchors.centerIn: parent
                        text: "📞"
                        font.pixelSize: 26
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (dialerRoot.dialedNumber.length > 0) {
                                dialerRoot.callStatus = "calling";
                                dialerRoot.callSeconds = 0;
                                // Auto-connect mock timer
                                connectTimer.start();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Backspace / Clear
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: "transparent"
                    visible: dialerRoot.dialedNumber.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "⌫"
                        font.pixelSize: 20
                        color: "#a0a5ad"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (dialerRoot.dialedNumber.length > 0) {
                                dialerRoot.dialedNumber = dialerRoot.dialedNumber.slice(0, -1);
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: connectTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (dialerRoot.callStatus === "calling") {
                dialerRoot.callStatus = "connected";
            }
        }
    }
}
