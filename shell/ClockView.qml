import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: clockRoot
    color: "#181b20"

    signal closeRequested()

    property string currentTab: "World Clock"
    property int stopwatchMs: 0
    property bool stopwatchRunning: false

    Timer {
        id: stopwatchTimer
        interval: 100
        repeat: true
        running: clockRoot.stopwatchRunning
        onTriggered: clockRoot.stopwatchMs += 100
    }

    function formatStopwatch(ms) {
        var totalSec = Math.floor(ms / 1000);
        var tenths = Math.floor((ms % 1000) / 100);
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + "." + tenths;
    }

    ListModel {
        id: alarmModel
    }

    Component.onCompleted: refreshAlarms()

    function refreshAlarms() {
        alarmModel.clear();
        if (typeof systemBackend !== "undefined") {
            var raw = systemBackend.getAlarms();
            try {
                var list = JSON.parse(raw);
                for (var i = 0; i < list.length; i++) {
                    alarmModel.append(list[i]);
                }
            } catch(e) {
                console.log("Error reading alarms: " + e);
            }
        }
        if (alarmModel.count === 0) {
            alarmModel.append({ id: 1, time: "07:00", label: "Morning Alarm", enabled: true });
            alarmModel.append({ id: 2, time: "08:30", label: "Work Standup", enabled: false });
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
                    text: "⏰ Clock & Timer"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#ffffff"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: clockRoot.closeRequested()
                }
            }
        }

        // Subtabs
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                spacing: 6

                Repeater {
                    model: ["World Clock", "Alarms", "Stopwatch"]
                    delegate: Button {
                        text: modelData
                        flat: clockRoot.currentTab !== modelData
                        highlighted: clockRoot.currentTab === modelData
                        implicitHeight: 28
                        onClicked: clockRoot.currentTab = modelData
                    }
                }
            }
        }

        // --- WORLD CLOCK VIEW ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: clockRoot.currentTab === "World Clock"
            spacing: 20

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                spacing: 6

                Text {
                    id: liveBigClock
                    text: Qt.formatTime(new Date(), "hh:mm:ss")
                    font.pixelSize: 48
                    font.weight: Font.Light
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
                    font.pixelSize: 14
                    color: "#3daee9"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Local System Timezone"
                    font.pixelSize: 12
                    color: "#a0a5ad"
                    Layout.alignment: Qt.AlignHCenter
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: liveBigClock.text = Qt.formatTime(new Date(), "hh:mm:ss")
                }
            }

            Item { Layout.fillHeight: true }
        }

        // --- ALARMS VIEW ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: clockRoot.currentTab === "Alarms"
            spacing: 10

            ListView {
                id: alarmListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 14
                spacing: 12
                model: alarmModel

                delegate: Rectangle {
                    width: alarmListView.width
                    height: 72
                    radius: 12
                    color: "#23262e"
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            Text {
                                text: model.time
                                font.bold: true
                                font.pixelSize: 24
                                color: model.enabled ? "#ffffff" : "#7f8c8d"
                            }
                            Text {
                                text: model.label
                                font.pixelSize: 12
                                color: "#a0a5ad"
                            }
                        }

                        Switch {
                            checked: model.enabled
                            onToggled: {
                                if (typeof systemBackend !== "undefined") {
                                    systemBackend.toggleAlarm(model.id, checked);
                                }
                                model.enabled = checked;
                            }
                        }
                    }
                }
            }
        }

        // --- STOPWATCH VIEW ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: clockRoot.currentTab === "Stopwatch"
            spacing: 30

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 50
                spacing: 12

                Text {
                    text: clockRoot.formatStopwatch(clockRoot.stopwatchMs)
                    font.family: "monospace"
                    font.pixelSize: 52
                    font.bold: true
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Button {
                        text: clockRoot.stopwatchRunning ? "Pause" : "Start"
                        highlighted: !clockRoot.stopwatchRunning
                        onClicked: clockRoot.stopwatchRunning = !clockRoot.stopwatchRunning
                    }

                    Button {
                        text: "Reset"
                        flat: true
                        onClicked: {
                            clockRoot.stopwatchRunning = false;
                            clockRoot.stopwatchMs = 0;
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
