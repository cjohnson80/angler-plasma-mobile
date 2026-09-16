import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: contactsRoot
    color: "#181b20"

    signal closeRequested()
    signal contactSelected(string name, string phone)

    property bool isAddingContact: false

    ListModel {
        id: contactsListModel
    }

    Component.onCompleted: {
        reloadContacts();
    }

    function reloadContacts() {
        if (typeof systemBackend !== "undefined") {
            try {
                var list = JSON.parse(systemBackend.getContacts());
                contactsListModel.clear();
                for (var i = 0; i < list.length; i++) {
                    contactsListModel.append({
                        contactId: list[i].id,
                        name: list[i].name,
                        phone: list[i].phone || "",
                        email: list[i].email || "",
                        category: list[i].category || "General"
                    });
                }
            } catch (e) {
                console.log("Error loading contacts:", e);
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
                    text: "👥 Contacts"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: contactsRoot.isAddingContact ? "Cancel" : "+ Add"
                    flat: true
                    onClicked: contactsRoot.isAddingContact = !contactsRoot.isAddingContact
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: contactsRoot.closeRequested()
                }
            }
        }

        // Add Contact Form
        Rectangle {
            Layout.fillWidth: true
            height: contactsRoot.isAddingContact ? 210 : 0
            visible: contactsRoot.isAddingContact
            color: "#23262e"
            clip: true

            Behavior on height { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: "Full Name"
                    color: "#ffffff"
                }

                TextField {
                    id: phoneField
                    Layout.fillWidth: true
                    placeholderText: "Phone Number"
                    inputMethodHints: Qt.ImhDialableCharactersOnly
                    color: "#ffffff"
                }

                TextField {
                    id: emailField
                    Layout.fillWidth: true
                    placeholderText: "Email Address"
                    color: "#ffffff"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Save Contact"
                        highlighted: true
                        onClicked: {
                            if (nameField.text.trim().length > 0) {
                                if (typeof systemBackend !== "undefined") {
                                    systemBackend.saveContact(nameField.text.trim(), phoneField.text.trim(), emailField.text.trim(), "Personal");
                                }
                                nameField.text = "";
                                phoneField.text = "";
                                emailField.text = "";
                                contactsRoot.isAddingContact = false;
                                contactsRoot.reloadContacts();
                            }
                        }
                    }
                }
            }
        }

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: "#181b20"

            TextField {
                id: searchBar
                anchors.fill: parent
                anchors.margins: 6
                placeholderText: "🔍 Search contacts..."
                color: "#ffffff"
            }
        }

        // Contact List
        ListView {
            id: contactsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: contactsListModel

            delegate: Rectangle {
                width: contactsView.width
                height: 64
                color: index % 2 === 0 ? "#1c1f26" : "#22262f"
                border.color: Qt.rgba(1, 1, 1, 0.04)

                visible: searchBar.text.length === 0 || model.name.toLowerCase().indexOf(searchBar.text.toLowerCase()) !== -1
                height: visible ? 64 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    // Avatar Circle
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: "#3daee9"

                        Text {
                            anchors.centerIn: parent
                            text: model.name.length > 0 ? model.name.charAt(0).toUpperCase() : "?"
                            font.bold: true
                            font.pixelSize: 18
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: model.name
                            font.bold: true
                            font.pixelSize: 14
                            color: "#ffffff"
                        }

                        Text {
                            text: model.phone !== "" ? model.phone : model.email
                            font.pixelSize: 12
                            color: "#a0a5ad"
                        }
                    }

                    // Direct Call Button
                    Button {
                        text: "📞"
                        flat: true
                        onClicked: {
                            contactsRoot.contactSelected(model.name, model.phone);
                        }
                    }

                    // Delete Contact Button
                    Button {
                        text: "🗑"
                        flat: true
                        onClicked: {
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.deleteContact(model.contactId);
                                contactsRoot.reloadContacts();
                            }
                        }
                    }
                }
            }
        }
    }
}
