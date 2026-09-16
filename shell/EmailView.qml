import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: emailRoot
    color: "#181b20"

    signal closeRequested()

    property bool isComposing: false
    property var selectedEmail: null

    ListModel {
        id: emailListModel
    }

    Component.onCompleted: {
        reloadEmails();
    }

    function reloadEmails() {
        if (typeof systemBackend !== "undefined") {
            try {
                var list = JSON.parse(systemBackend.getEmails());
                emailListModel.clear();
                for (var i = 0; i < list.length; i++) {
                    emailListModel.append({
                        emailId: list[i].id,
                        sender: list[i].sender,
                        senderEmail: list[i].senderEmail,
                        subject: list[i].subject,
                        body: list[i].body,
                        dateStr: list[i].dateStr,
                        isRead: list[i].isRead,
                        isStarred: list[i].isStarred
                    });
                }
            } catch (e) {
                console.log("Error loading emails:", e);
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
                    text: emailRoot.selectedEmail !== null ? "✉ Message Details" : "✉ Mail"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: emailRoot.selectedEmail !== null ? "Back" : (emailRoot.isComposing ? "Cancel" : "✏ Compose")
                    flat: true
                    onClicked: {
                        if (emailRoot.selectedEmail !== null) {
                            emailRoot.selectedEmail = null;
                        } else {
                            emailRoot.isComposing = !emailRoot.isComposing;
                        }
                    }
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: emailRoot.closeRequested()
                }
            }
        }

        // Compose Drawer
        Rectangle {
            Layout.fillWidth: true
            height: emailRoot.isComposing ? 240 : 0
            visible: emailRoot.isComposing
            color: "#23262e"
            clip: true

            Behavior on height { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                TextField {
                    id: toField
                    Layout.fillWidth: true
                    placeholderText: "To (e.g. user@example.com)"
                    color: "#ffffff"
                }

                TextField {
                    id: subjectField
                    Layout.fillWidth: true
                    placeholderText: "Subject"
                    color: "#ffffff"
                }

                TextArea {
                    id: bodyField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Write your message..."
                    color: "#ffffff"
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Send Email"
                        highlighted: true
                        onClicked: {
                            if (toField.text.trim().length > 0 && subjectField.text.trim().length > 0) {
                                if (typeof systemBackend !== "undefined") {
                                    systemBackend.sendEmail(toField.text.trim(), subjectField.text.trim(), bodyField.text.trim());
                                }
                                toField.text = "";
                                subjectField.text = "";
                                bodyField.text = "";
                                emailRoot.isComposing = false;
                                emailRoot.reloadEmails();
                            }
                        }
                    }
                }
            }
        }

        // Detail View (when message tapped)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: emailRoot.selectedEmail !== null
            color: "#181b20"

            ScrollView {
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 14
                    Layout.margins: 16

                    Text {
                        Layout.fillWidth: true
                        text: emailRoot.selectedEmail ? emailRoot.selectedEmail.subject : ""
                        font.bold: true
                        font.pixelSize: 20
                        wrapMode: Text.WordWrap
                        color: "#ffffff"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: "#3daee9"
                            Text {
                                anchors.centerIn: parent
                                text: emailRoot.selectedEmail && emailRoot.selectedEmail.sender ? emailRoot.selectedEmail.sender.charAt(0) : "M"
                                font.bold: true
                                color: "#ffffff"
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: emailRoot.selectedEmail ? emailRoot.selectedEmail.sender : ""
                                font.bold: true
                                font.pixelSize: 13
                                color: "#ffffff"
                            }
                            Text {
                                text: emailRoot.selectedEmail ? "<" + emailRoot.selectedEmail.senderEmail + ">" : ""
                                font.pixelSize: 11
                                color: "#a0a5ad"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: emailRoot.selectedEmail ? emailRoot.selectedEmail.dateStr : ""
                            font.pixelSize: 12
                            color: "#3daee9"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: emailRoot.selectedEmail ? emailRoot.selectedEmail.body : ""
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                        color: "#fcfcfc"
                    }
                }
            }
        }

        // Message List
        ListView {
            id: emailsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: emailRoot.selectedEmail === null
            model: emailListModel

            delegate: Rectangle {
                width: emailsView.width
                height: 76
                color: model.isRead ? "#1a1d24" : "#232731"
                border.color: Qt.rgba(1, 1, 1, 0.04)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (typeof systemBackend !== "undefined") {
                            systemBackend.markEmailRead(model.emailId);
                        }
                        model.isRead = true;
                        emailRoot.selectedEmail = {
                            emailId: model.emailId,
                            sender: model.sender,
                            senderEmail: model.senderEmail,
                            subject: model.subject,
                            body: model.body,
                            dateStr: model.dateStr
                        };
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Unread Indicator Pill
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: model.isRead ? "transparent" : "#3daee9"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: model.sender
                                font.bold: !model.isRead
                                font.pixelSize: 14
                                color: "#ffffff"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: model.dateStr
                                font.pixelSize: 11
                                color: "#a0a5ad"
                            }
                        }

                        Text {
                            text: model.subject
                            font.bold: !model.isRead
                            font.pixelSize: 13
                            color: model.isRead ? "#a0a5ad" : "#ffffff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.body
                            font.pixelSize: 11
                            color: "#7f8c8d"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Star Button
                    Button {
                        text: model.isStarred ? "★" : "☆"
                        flat: true
                        implicitWidth: 32
                        onClicked: {
                            var newState = !model.isStarred;
                            model.isStarred = newState;
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.toggleStarEmail(model.emailId, newState);
                            }
                        }
                    }

                    // Delete Button
                    Button {
                        text: "🗑"
                        flat: true
                        implicitWidth: 32
                        onClicked: {
                            if (typeof systemBackend !== "undefined") {
                                systemBackend.deleteEmail(model.emailId);
                                emailRoot.reloadEmails();
                            }
                        }
                    }
                }
            }
        }
    }
}
