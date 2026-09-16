import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: calendarRoot
    color: "#181b20"

    signal closeRequested()

    property bool isAddingEvent: false
    property string selectedDate: ""
    property int currentMonth: 8 // September (0-indexed)
    property int currentYear: 2026

    ListModel {
        id: eventsListModel
    }

    Component.onCompleted: {
        var today = new Date();
        calendarRoot.selectedDate = today.toISOString().split('T')[0];
        reloadEvents();
    }

    function reloadEvents() {
        if (typeof systemBackend !== "undefined") {
            try {
                var list = JSON.parse(systemBackend.getEvents(calendarRoot.selectedDate));
                eventsListModel.clear();
                for (var i = 0; i < list.length; i++) {
                    eventsListModel.append({
                        eventId: list[i].id,
                        title: list[i].title,
                        dateStr: list[i].date,
                        timeStr: list[i].time || "",
                        location: list[i].location || "",
                        description: list[i].description || ""
                    });
                }
            } catch (e) {
                console.log("Error loading events:", e);
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
                    text: "📅 Calendar & Agenda"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: calendarRoot.isAddingEvent ? "Cancel" : "+ Event"
                    flat: true
                    onClicked: calendarRoot.isAddingEvent = !calendarRoot.isAddingEvent
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: calendarRoot.closeRequested()
                }
            }
        }

        // Add Event Panel
        Rectangle {
            Layout.fillWidth: true
            height: calendarRoot.isAddingEvent ? 220 : 0
            visible: calendarRoot.isAddingEvent
            color: "#23262e"
            clip: true

            Behavior on height { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                TextField {
                    id: eventTitleField
                    Layout.fillWidth: true
                    placeholderText: "Event Title"
                    color: "#ffffff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: eventDateField
                        Layout.fillWidth: true
                        text: calendarRoot.selectedDate
                        placeholderText: "YYYY-MM-DD"
                        color: "#ffffff"
                    }
                    TextField {
                        id: eventTimeField
                        Layout.fillWidth: true
                        placeholderText: "Time (e.g. 14:00)"
                        color: "#ffffff"
                    }
                }

                TextField {
                    id: eventLocationField
                    Layout.fillWidth: true
                    placeholderText: "Location / Device"
                    color: "#ffffff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Add to Calendar"
                        highlighted: true
                        onClicked: {
                            if (eventTitleField.text.trim().length > 0) {
                                if (typeof systemBackend !== "undefined") {
                                    systemBackend.addEvent(
                                        eventTitleField.text.trim(),
                                        eventDateField.text.trim(),
                                        eventTimeField.text.trim(),
                                        eventLocationField.text.trim(),
                                        "Created from Plasma Mobile"
                                    );
                                }
                                eventTitleField.text = "";
                                eventTimeField.text = "";
                                calendarRoot.isAddingEvent = false;
                                calendarRoot.reloadEvents();
                            }
                        }
                    }
                }
            }
        }

        // Calendar Month Matrix
        Rectangle {
            Layout.fillWidth: true
            height: 200
            color: "#1c1f26"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Month navigation
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "September 2026"
                        font.bold: true
                        font.pixelSize: 14
                        color: "#3daee9"
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "Today"
                        flat: true
                        implicitHeight: 28
                        onClicked: {
                            var today = new Date();
                            calendarRoot.selectedDate = today.toISOString().split('T')[0];
                            calendarRoot.reloadEvents();
                        }
                    }
                }

                // Days grid (Sun - Sat)
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                        delegate: Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.pixelSize: 11
                            color: "#7f8c8d"
                        }
                    }
                }

                // Days numbers
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: 35 // 5 weeks
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            readonly property int dayNum: index - 1 // Sep 1 2026 is Tuesday
                            readonly property bool isCurrentMonth: dayNum >= 1 && dayNum <= 30
                            readonly property string cellDate: "2026-09-" + (dayNum < 10 ? "0" + dayNum : dayNum)
                            readonly property bool isSelected: calendarRoot.selectedDate === cellDate

                            color: isSelected ? "#3daee9" : (isCurrentMonth ? "#23262e" : "transparent")
                            opacity: isCurrentMonth ? 1.0 : 0.2

                            Text {
                                anchors.centerIn: parent
                                text: isCurrentMonth ? dayNum.toString() : ""
                                font.pixelSize: 12
                                font.bold: isSelected
                                color: isSelected ? "#ffffff" : "#fcfcfc"
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: isCurrentMonth
                                onClicked: {
                                    calendarRoot.selectedDate = cellDate;
                                    calendarRoot.reloadEvents();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Agenda Header
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#181b20"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Text {
                    text: "Events on " + calendarRoot.selectedDate
                    font.bold: true
                    font.pixelSize: 13
                    color: "#a0a5ad"
                    Layout.fillWidth: true
                }
            }
        }

        // Agenda Event List
        ListView {
            id: eventsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: eventsListModel

            delegate: Rectangle {
                width: eventsView.width
                height: 68
                color: "#23262e"
                border.color: Qt.rgba(1, 1, 1, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 4
                        Layout.fillHeight: true
                        color: "#2ecc71"
                        radius: 2
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: model.title
                            font.bold: true
                            font.pixelSize: 14
                            color: "#ffffff"
                        }

                        Text {
                            text: (model.timeStr !== "" ? "⏰ " + model.timeStr + "  •  " : "") + (model.location !== "" ? "📍 " + model.location : "")
                            font.pixelSize: 12
                            color: "#3daee9"
                        }
                    }

                    Button {
                        text: "✕"
                        flat: true
                        onClicked: {
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.deleteEvent(model.eventId);
                                calendarRoot.reloadEvents();
                            }
                        }
                    }
                }
            }
        }
    }
}
