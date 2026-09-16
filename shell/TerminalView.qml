import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: terminalView
    color: "#14171a"

    signal closeRequested()

    property string workingDir: "~"
    property var history: [
        "Welcome to Plasma Mobile Konsole!",
        "Live Subprocess Shell Connected.",
        ""
    ]

    Connections {
        target: typeof systemBackend !== "undefined" ? systemBackend : null
        function onTerminalOutputReady(output) {
            var lines = output.split("\n");
            var newHist = terminalView.history.slice();
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].length > 0) newHist.push(lines[i]);
            }
            terminalView.history = newHist;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Bar
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12

                Text {
                    text: "⌨ konsole-mobile: " + terminalView.workingDir
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#fcfcfc"
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: terminalView.closeRequested()
                }
            }
        }

        // Output History
        ListView {
            id: outputList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 12
            clip: true
            model: terminalView.history

            delegate: Text {
                width: outputList.width
                text: modelData
                color: modelData.startsWith("$ ") ? "#3daee9" :
                       modelData.startsWith("Error:") ? "#e74c3c" : "#d0d4dc"
                font.family: "monospace"
                font.pixelSize: 12
                wrapMode: Text.WrapAnywhere
            }

            onCountChanged: outputList.positionViewAtEnd()
        }

        // Quick Keys Bar
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#1c1f26"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Repeater {
                    model: ["ls -la", "pwd", "df -h", "free -m", "uname -a", "clear"]
                    delegate: Button {
                        text: modelData
                        flat: true
                        implicitHeight: 28
                        onClicked: {
                            if (modelData === "clear") {
                                terminalView.history = [];
                            } else {
                                executeCommand(modelData);
                            }
                        }
                    }
                }
            }
        }

        // Input Line
        Rectangle {
            Layout.fillWidth: true
            height: 46
            color: "#1a1d24"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "$ "
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#3daee9"
                }

                TextInput {
                    id: cmdInput
                    Layout.fillWidth: true
                    color: "#ffffff"
                    font.family: "monospace"
                    font.pixelSize: 13
                    focus: true

                    onAccepted: {
                        var cmd = text.trim();
                        text = "";
                        executeCommand(cmd);
                    }
                }

                Button {
                    text: "Run"
                    highlighted: true
                    onClicked: {
                        var cmd = cmdInput.text.trim();
                        cmdInput.text = "";
                        executeCommand(cmd);
                    }
                }
            }
        }
    }

    function executeCommand(cmd) {
        if (cmd === "") return;
        var newHist = terminalView.history.slice();
        newHist.push("$ " + cmd);
        terminalView.history = newHist;

        if (cmd === "clear") {
            terminalView.history = [];
            return;
        }

        if (cmd.startsWith("cd ")) {
            var target = cmd.slice(3).trim();
            terminalView.workingDir = target;
            newHist.push("[Directory changed to " + target + "]");
            terminalView.history = newHist;
            return;
        }

        if (typeof systemBackend !== "undefined") {
            systemBackend.runTerminalCommand(cmd, terminalView.workingDir);
        } else {
            newHist.push("[Local Simulated Response for: " + cmd + "]");
            terminalView.history = newHist;
        }
    }
}
