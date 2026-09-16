import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: notesRoot
    color: "#181b20"

    signal closeRequested()

    property bool isEditing: false
    property int selectedNoteId: -1

    ListModel {
        id: notesListModel
    }

    Component.onCompleted: refreshNotes()

    function refreshNotes() {
        notesListModel.clear();
        if (typeof systemBackend !== "undefined") {
            var raw = systemBackend.getNotes();
            try {
                var list = JSON.parse(raw);
                for (var i = 0; i < list.length; i++) {
                    notesListModel.append(list[i]);
                }
            } catch(e) {
                console.log("Error parsing notes: " + e);
            }
        } else {
            notesListModel.append({ id: 1, title: "Nexus 6P Notes", content: "Plasma 6 running on MSM8994!", updatedAt: "2026-09-16" });
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
                    text: notesRoot.isEditing ? "📝 New Note" : "📝 Notes (" + notesListModel.count + ")"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#ffffff"
                    Layout.fillWidth: true
                }

                Button {
                    text: notesRoot.isEditing ? "Cancel" : "+ New"
                    flat: true
                    onClicked: {
                        notesRoot.isEditing = !notesRoot.isEditing;
                        noteTitleInput.text = "";
                        noteContentInput.text = "";
                    }
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: {
                        notesRoot.isEditing = false;
                        notesRoot.closeRequested();
                    }
                }
            }
        }

        // Note Editor View
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#181b20"
            visible: notesRoot.isEditing

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                TextField {
                    id: noteTitleInput
                    Layout.fillWidth: true
                    placeholderText: "Note Title"
                    font.bold: true
                    font.pixelSize: 16
                }

                TextArea {
                    id: noteContentInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Type note details..."
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }

                Button {
                    Layout.fillWidth: true
                    text: "Save Note to SQLite Database"
                    highlighted: true
                    onClicked: {
                        var t = noteTitleInput.text.trim();
                        var c = noteContentInput.text.trim();
                        if (t === "" && c === "") return;
                        if (t === "") t = "Untitled Note";

                        if (typeof systemBackend !== "undefined") {
                            systemBackend.saveNote(t, c);
                        } else {
                            notesListModel.append({ id: Date.now(), title: t, content: c, updatedAt: "Just now" });
                        }

                        notesRoot.isEditing = false;
                        notesRoot.refreshNotes();
                    }
                }
            }
        }

        // Notes Cards List
        ListView {
            id: notesListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 14
            spacing: 12
            clip: true
            visible: !notesRoot.isEditing
            model: notesListModel

            delegate: Rectangle {
                width: notesListView.width
                height: 80
                radius: 12
                color: "#23262e"
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: model.title
                            font.bold: true
                            font.pixelSize: 15
                            color: "#ffffff"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.content
                            font.pixelSize: 12
                            color: "#a0a5ad"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.updatedAt
                            font.pixelSize: 10
                            color: "#3daee9"
                        }
                    }

                    Button {
                        text: "🗑"
                        flat: true
                        onClicked: {
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.deleteNote(model.id);
                                notesRoot.refreshNotes();
                            } else {
                                notesListModel.remove(index);
                            }
                        }
                    }
                }
            }
        }
    }
}
