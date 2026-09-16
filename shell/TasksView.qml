import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: tasksRoot
    color: "#181b20"

    signal closeRequested()

    ListModel {
        id: tasksListModel
    }

    Component.onCompleted: {
        reloadTasks();
    }

    function reloadTasks() {
        if (typeof systemBackend !== "undefined") {
            try {
                var list = JSON.parse(systemBackend.getTasks());
                tasksListModel.clear();
                for (var i = 0; i < list.length; i++) {
                    tasksListModel.append({
                        taskId: list[i].id,
                        task: list[i].task,
                        completed: list[i].completed,
                        dueDate: list[i].dueDate || ""
                    });
                }
            } catch (e) {
                console.log("Error loading tasks:", e);
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
                    text: "✓ Tasks & To-Do"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: tasksRoot.closeRequested()
                }
            }
        }

        // Add Task Input Row
        Rectangle {
            Layout.fillWidth: true
            height: 58
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                TextField {
                    id: newTaskField
                    Layout.fillWidth: true
                    placeholderText: "What needs to be done?"
                    color: "#ffffff"
                    onAccepted: addTaskBtn.clicked()
                }

                Button {
                    id: addTaskBtn
                    text: "+ Add"
                    highlighted: true
                    onClicked: {
                        if (newTaskField.text.trim().length > 0) {
                            if (typeof systemBackend !== "undefined") {
                                var todayStr = new Date().toISOString().split('T')[0];
                                systemBackend.addTask(newTaskField.text.trim(), todayStr);
                            }
                            newTaskField.text = "";
                            tasksRoot.reloadTasks();
                        }
                    }
                }
            }
        }

        // Task List
        ListView {
            id: tasksView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: tasksListModel

            delegate: Rectangle {
                width: tasksView.width
                height: 56
                color: model.completed ? "#1a1c22" : "#23262e"
                border.color: Qt.rgba(1, 1, 1, 0.04)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    CheckBox {
                        checked: model.completed
                        onToggled: {
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.toggleTask(model.taskId, checked);
                                tasksRoot.reloadTasks();
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: model.task
                            font.pixelSize: 14
                            font.strikeout: model.completed
                            color: model.completed ? "#7f8c8d" : "#ffffff"
                        }

                        Text {
                            text: "Due: " + (model.dueDate !== "" ? model.dueDate : "Today")
                            font.pixelSize: 11
                            color: "#3daee9"
                            visible: !model.completed
                        }
                    }

                    Button {
                        text: "🗑"
                        flat: true
                        onClicked: {
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.deleteTask(model.taskId);
                                tasksRoot.reloadTasks();
                            }
                        }
                    }
                }
            }
        }
    }
}
