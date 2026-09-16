import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: mediaRoot
    color: "#181b20"

    signal closeRequested()

    property bool isPlaying: false
    property int currentTrackIndex: 0
    property real progress: 0.35

    ListModel {
        id: playlistModel
        ListElement { title: "KDE Plasma Breeze Theme"; artist: "KDE Community"; duration: "3:42" }
        ListElement { title: "Arch Linux Freedom Sound"; artist: "Open Source Collective"; duration: "4:15" }
        ListElement { title: "Snapdragon 810 Beats"; artist: "Adreno Sound Team"; duration: "2:58" }
        ListElement { title: "Ambient AMOLED Night"; artist: "PulseAudio Stream"; duration: "5:20" }
    }

    Timer {
        interval: 1000
        repeat: true
        running: mediaRoot.isPlaying
        onTriggered: {
            mediaRoot.progress += 0.01;
            if (mediaRoot.progress >= 1.0) mediaRoot.progress = 0.0;
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
                    text: "🎵 Elisa Music Player"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#ffffff"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: {
                        mediaRoot.isPlaying = false;
                        mediaRoot.closeRequested();
                    }
                }
            }
        }

        // Album Art View
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#14171a"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 160
                    height: 160
                    radius: 20
                    color: "#2a2e38"
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "💿"
                        font.pixelSize: 72
                    }
                }

                Text {
                    text: playlistModel.get(mediaRoot.currentTrackIndex).title
                    font.bold: true
                    font.pixelSize: 18
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: playlistModel.get(mediaRoot.currentTrackIndex).artist
                    font.pixelSize: 13
                    color: "#3daee9"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Progress Slider & Controls
        Rectangle {
            Layout.fillWidth: true
            height: 130
            color: "#1f232a"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Slider {
                    Layout.fillWidth: true
                    value: mediaRoot.progress
                    onMoved: mediaRoot.progress = value
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    Button {
                        text: "⏮"
                        flat: true
                        onClicked: {
                            if (mediaRoot.currentTrackIndex > 0) mediaRoot.currentTrackIndex--;
                            else mediaRoot.currentTrackIndex = playlistModel.count - 1;
                            mediaRoot.progress = 0.0;
                        }
                    }

                    Rectangle {
                        width: 54
                        height: 54
                        radius: 27
                        color: "#3daee9"

                        Text {
                            anchors.centerIn: parent
                            text: mediaRoot.isPlaying ? "⏸" : "▶"
                            font.pixelSize: 22
                            color: "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mediaRoot.isPlaying = !mediaRoot.isPlaying
                        }
                    }

                    Button {
                        text: "⏭"
                        flat: true
                        onClicked: {
                            if (mediaRoot.currentTrackIndex < playlistModel.count - 1) mediaRoot.currentTrackIndex++;
                            else mediaRoot.currentTrackIndex = 0;
                            mediaRoot.progress = 0.0;
                        }
                    }
                }
            }
        }
    }
}
