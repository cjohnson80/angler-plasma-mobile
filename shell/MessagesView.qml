import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: messagesRoot
    color: "#181b20"

    signal closeRequested()

    property string currentContact: "+1 (555) 019-2834"

    ListModel {
        id: chatModel
    }

    Component.onCompleted: loadMessages()

    function loadMessages() {
        chatModel.clear();
        if (typeof systemBackend !== "undefined") {
            var raw = systemBackend.getMessages();
            try {
                var list = JSON.parse(raw);
                for (var i = 0; i < list.length; i++) {
                    chatModel.append(list[i]);
                }
            } catch(e) {
                console.log("Error loading messages: " + e);
            }
        } else {
            chatModel.append({ body: "Welcome to Plasma Mobile Messaging!", timestamp: "10:00", isIncoming: true });
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Conversation Header
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: "#3daee9"

                    Text {
                        anchors.centerIn: parent
                        text: "💬"
                        font.pixelSize: 18
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: messagesRoot.currentContact
                        font.bold: true
                        font.pixelSize: 14
                        color: "#ffffff"
                    }
                    Text {
                        text: "SMS / MMS via ModemManager"
                        font.pixelSize: 11
                        color: "#a0a5ad"
                    }
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: messagesRoot.closeRequested()
                }
            }
        }

        // Messages Bubble Stream
        ListView {
            id: chatListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 12
            spacing: 10
            clip: true
            model: chatModel

            delegate: RowLayout {
                width: chatListView.width
                layoutDirection: model.isIncoming ? Qt.LeftToRight : Qt.RightToLeft

                Rectangle {
                    Layout.maximumWidth: chatListView.width * 0.75
                    implicitWidth: msgCol.implicitWidth + 24
                    implicitHeight: msgCol.implicitHeight + 16
                    radius: 16
                    color: model.isIncoming ? "#2a2e38" : "#3daee9"

                    ColumnLayout {
                        id: msgCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            text: model.body
                            font.pixelSize: 14
                            color: "#ffffff"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.timestamp
                            font.pixelSize: 10
                            color: model.isIncoming ? "#a0a5ad" : Qt.rgba(1, 1, 1, 0.7)
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }

            onCountChanged: chatListView.positionViewAtEnd()
        }

        // Input & Send Bar
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 20
                    color: "#2a2e38"

                    TextInput {
                        id: msgInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font.pixelSize: 14

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: msgInput.text === "" ? "Send an SMS message..." : ""
                            color: "#7f8c8d"
                            font.pixelSize: 14
                            visible: !msgInput.activeFocus && msgInput.text === ""
                        }

                        onAccepted: sendBtn.sendCurrentMessage()
                    }
                }

                Button {
                    id: sendBtn
                    text: "Send"
                    highlighted: true

                    function sendCurrentMessage() {
                        var text = msgInput.text.trim();
                        if (text === "") return;
                        msgInput.text = "";

                        var now = Qt.formatTime(new Date(), "hh:mm");
                        chatModel.append({
                            body: text,
                            timestamp: now,
                            isIncoming: false
                        });

                        if (typeof systemBackend !== "undefined") {
                            systemBackend.sendMessage(messagesRoot.currentContact, text);
                        }
                    }

                    onClicked: sendCurrentMessage()
                }
            }
        }
    }
}
