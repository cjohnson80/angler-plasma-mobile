import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: calcRoot
    color: "#181b20"

    signal closeRequested()

    property string displayExpr: ""
    property string displayResult: "0"

    function pushDigit(d) {
        if (displayResult === "0" && d !== ".") {
            displayResult = d;
        } else {
            displayResult += d;
        }
    }

    function pushOp(op) {
        if (displayResult !== "") {
            displayExpr = displayResult + " " + op + " ";
            displayResult = "";
        }
    }

    function calculate() {
        if (displayExpr === "" || displayResult === "") return;
        var full = displayExpr + displayResult;
        try {
            // Safe evaluation of mathematical operators
            var sanitized = full.replace(/×/g, "*").replace(/÷/g, "/");
            var res = Function("return " + sanitized)();
            displayExpr = full + " =";
            displayResult = String(res);
        } catch(e) {
            displayResult = "Error";
        }
    }

    function clearAll() {
        displayExpr = "";
        displayResult = "0";
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
                    text: "🧮 Calculator"
                    font.bold: true
                    font.pixelSize: 14
                    color: "#ffffff"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: calcRoot.closeRequested()
                }
            }
        }

        // Display Screen
        Rectangle {
            Layout.fillWidth: true
            height: 120
            color: "#14171a"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 6

                Text {
                    text: calcRoot.displayExpr
                    font.pixelSize: 14
                    color: "#a0a5ad"
                    Layout.alignment: Qt.AlignRight
                }

                Text {
                    text: calcRoot.displayResult
                    font.pixelSize: 42
                    font.bold: true
                    color: "#ffffff"
                    elide: Text.ElideLeft
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        // Keypad Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 14
            columns: 4
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: [
                    { label: "C", type: "action", color: "#e74c3c" },
                    { label: "±", type: "fn", color: "#2a2e38" },
                    { label: "%", type: "fn", color: "#2a2e38" },
                    { label: "÷", type: "op", color: "#3daee9" },
                    { label: "7", type: "num", color: "#23262e" },
                    { label: "8", type: "num", color: "#23262e" },
                    { label: "9", type: "num", color: "#23262e" },
                    { label: "×", type: "op", color: "#3daee9" },
                    { label: "4", type: "num", color: "#23262e" },
                    { label: "5", type: "num", color: "#23262e" },
                    { label: "6", type: "num", color: "#23262e" },
                    { label: "-", type: "op", color: "#3daee9" },
                    { label: "1", type: "num", color: "#23262e" },
                    { label: "2", type: "num", color: "#23262e" },
                    { label: "3", type: "num", color: "#23262e" },
                    { label: "+", type: "op", color: "#3daee9" },
                    { label: "0", type: "num", color: "#23262e" },
                    { label: ".", type: "num", color: "#23262e" },
                    { label: "⌫", type: "action", color: "#2a2e38" },
                    { label: "=", type: "calc", color: "#2ecc71" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: modelData.color

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 22
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var l = modelData.label;
                            if (l === "C") calcRoot.clearAll();
                            else if (l === "=") calcRoot.calculate();
                            else if (l === "⌫") {
                                if (calcRoot.displayResult.length > 1) {
                                    calcRoot.displayResult = calcRoot.displayResult.slice(0, -1);
                                } else {
                                    calcRoot.displayResult = "0";
                                }
                            } else if (l === "±") {
                                if (calcRoot.displayResult.startsWith("-")) {
                                    calcRoot.displayResult = calcRoot.displayResult.slice(1);
                                } else if (calcRoot.displayResult !== "0") {
                                    calcRoot.displayResult = "-" + calcRoot.displayResult;
                                }
                            } else if (l === "+" || l === "-" || l === "×" || l === "÷") {
                                calcRoot.pushOp(l);
                            } else {
                                calcRoot.pushDigit(l);
                            }
                        }
                    }
                }
            }
        }
    }
}
