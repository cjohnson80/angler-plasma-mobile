import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: terminalView
    color: "#14171a"

    signal closeRequested()

    property var history: [
        "Welcome to Arch Linux ARM on Nexus 6P (angler)!",
        "Kernel: 3.10.73-halium-angler aarch64",
        "Display: 2560x1440 AMOLED @ Adreno 430 (libhybris hwcomposer)",
        "Type 'help' for a list of built-in demo commands.",
        ""
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Terminal Top Bar
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12

                Text {
                    text: "⌨ konsole-mobile: chris@angler"
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
                color: modelData.startsWith("chris@angler") ? "#3daee9" :
                       modelData.startsWith("[ERROR]") ? "#e74c3c" :
                       modelData.startsWith("[OK]") ? "#2ecc71" : "#d0d4dc"
                font.family: "monospace"
                font.pixelSize: 12
                wrapMode: Text.WrapAnywhere
            }

            onCountChanged: outputList.positionViewAtEnd()
        }

        // Virtual Touch Keyboard / Quick Key Bar
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
                    model: ["Tab", "Ctrl", "Alt", "Esc", "|", "-", "/", "~", "clear"]
                    delegate: Button {
                        text: modelData
                        flat: true
                        implicitHeight: 28
                        onClicked: {
                            if (modelData === "clear") {
                                terminalView.history = [];
                            } else if (modelData === "Tab") {
                                cmdInput.text += "    ";
                            } else {
                                cmdInput.text += modelData;
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
                    text: "chris@angler:~$ "
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 13
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
                    text: "Send"
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
        var newHistory = history.slice();
        newHistory.push("chris@angler:~$ " + cmd);

        if (cmd === "") {
            // No action
        } else if (cmd === "clear") {
            newHistory = [];
        } else if (cmd === "help") {
            newHistory.push("Available commands:");
            newHistory.push("  uname -a     : Show kernel and CPU architecture");
            newHistory.push("  lscpu        : Display CPU cluster topology (Snapdragon 810)");
            newHistory.push("  hybris-check : Run libhybris hardware tests");
            newHistory.push("  free -m      : Show RAM usage stats");
            newHistory.push("  clear        : Clear terminal output");
        } else if (cmd === "uname -a" || cmd === "uname -r") {
            newHistory.push("Linux angler-plasma 3.10.73-halium-angler #1 SMP PREEMPT aarch64 GNU/Linux");
        } else if (cmd === "lscpu") {
            newHistory.push("Architecture:          aarch64");
            newHistory.push("Byte Order:            Little Endian");
            newHistory.push("CPU(s):                8 (4x Cortex-A53 @ 1.55GHz, 4x Cortex-A57 @ 2.0GHz)");
            newHistory.push("Model name:            Qualcomm Snapdragon 810 (MSM8994)");
        } else if (cmd === "hybris-check") {
            newHistory.push("[OK] /dev/binder, /dev/hwbinder, /dev/vndbinder present");
            newHistory.push("[OK] /dev/kgsl-3d0 (Qualcomm Adreno 430) mapped");
            newHistory.push("[OK] Android 8.1 LXC container active (PID 412)");
            newHistory.push("[OK] libEGL_hybris.so -> libEGL_adreno.so bound successfully");
            newHistory.push("[OK] SurfaceComposerClient initialized at 2560x1440");
        } else if (cmd === "free -m") {
            newHistory.push("               total        used        free      shared  buff/cache   available");
            newHistory.push("Mem:            2870         410        1890          45         570        2380");
            newHistory.push("Swap:           1024           0        1024");
        } else {
            newHistory.push("[ERROR] " + cmd + ": command not found. Type 'help' for options.");
        }

        terminalView.history = newHistory;
    }
}
