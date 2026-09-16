import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settingsView
    color: "#181b20"

    signal closeRequested()

    property string currentSection: "About"

    // Real system state
    property bool wifiEnabled: true
    property bool btEnabled: false
    property bool mobileDataEnabled: true
    property bool nightLightEnabled: true
    property string governor: "interactive"

    property string uptimeStr: "Loading..."
    property string ramUsageStr: "Loading..."
    property string batteryPercentStr: "100%"
    property string batteryStatusStr: "Discharging"
    property string cpuTempStr: "42°C"
    property var wifiNetworksList: []

    Timer {
        id: statsTimer
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (typeof systemBackend !== "undefined") {
                try {
                    var stats = JSON.parse(systemBackend.getSystemStats());
                    settingsView.uptimeStr = stats.uptime || "N/A";
                    settingsView.ramUsageStr = (stats.ram_used || "0 MB") + " / " + (stats.ram_total || "3.0 GB");
                    settingsView.batteryPercentStr = (stats.battery_percent || 100) + "%";
                    settingsView.batteryStatusStr = stats.battery_status || "Discharging";
                    settingsView.cpuTempStr = stats.cpu_temp || "N/A";
                } catch (e) {
                    console.log("Stats parse error:", e);
                }
            }
        }
    }

    function scanWifi() {
        if (typeof systemBackend !== "undefined") {
            try {
                settingsView.wifiNetworksList = JSON.parse(systemBackend.getWifiNetworks());
            } catch (e) {}
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Settings Header
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "#1f232a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12

                Text {
                    text: "⚙ System Settings: " + settingsView.currentSection
                    font.bold: true
                    font.pixelSize: 14
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: settingsView.closeRequested()
                }
            }
        }

        // Section Tabs
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 4

                Repeater {
                    model: ["About", "Connectivity", "Hardware", "Battery"]
                    delegate: Button {
                        text: modelData
                        flat: settingsView.currentSection !== modelData
                        highlighted: settingsView.currentSection === modelData
                        implicitHeight: 28
                        onClicked: settingsView.currentSection = modelData
                    }
                }
            }
        }

        // Section Content
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 12
                Layout.margins: 16

                // --- ABOUT SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: settingsView.currentSection === "About"
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 72
                        radius: 12
                        color: "#2a2e38"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 10
                                color: "#3daee9"
                                Text {
                                    anchors.centerIn: parent
                                    text: "📱"
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: "Huawei Nexus 6P (angler)"; font.bold: true; font.pixelSize: 15; color: "#ffffff" }
                                Text { text: "KDE Plasma 6 Mobile Edition"; font.pixelSize: 12; color: "#3daee9" }
                            }
                        }
                    }

                    // Hardware Info Cards
                    Repeater {
                        model: [
                            { key: "Processor", val: "Qualcomm Snapdragon 810 (MSM8994)" },
                            { key: "GPU", val: "Adreno 430 @ 650 MHz (libhybris hwcomposer)" },
                            { key: "Display", val: '5.7" WQHD (2560x1440) AMOLED' },
                            { key: "Memory (RAM)", val: "3 GB LPDDR4" },
                            { key: "Kernel", val: "Linux 3.10.73-halium-angler (aarch64)" },
                            { key: "Userspace", val: "Arch Linux ARM64 (glibc / systemd)" },
                            { key: "Compositor", val: "Wayland / Qt 6.11.2" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 10
                            color: "#23262e"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                Text { text: modelData.key; color: "#a0a5ad"; font.pixelSize: 13 }
                                Item { Layout.fillWidth: true }
                                Text { text: modelData.val; font.bold: true; color: "#ffffff"; font.pixelSize: 13 }
                            }
                        }
                    }
                }

                // --- CONNECTIVITY SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: settingsView.currentSection === "Connectivity"
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: "#23262e"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "Wi-Fi (Broadcom BCM4358)"; font.bold: true; color: "#ffffff"; Layout.fillWidth: true }
                            Switch {
                                checked: settingsView.wifiEnabled
                                onToggled: settingsView.wifiEnabled = checked
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: "#23262e"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "Cellular Radio (Qualcomm MDM9635M)"; font.bold: true; color: "#ffffff"; Layout.fillWidth: true }
                            Switch {
                                checked: settingsView.mobileDataEnabled
                                onToggled: settingsView.mobileDataEnabled = checked
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: "#23262e"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "Bluetooth 4.2 LE"; font.bold: true; color: "#ffffff"; Layout.fillWidth: true }
                            Switch {
                                checked: settingsView.btEnabled
                                onToggled: settingsView.btEnabled = checked
                            }
                        }
                    }
                }

                // --- HARDWARE & THERMAL TUNING ---
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: settingsView.currentSection === "Hardware"
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 80
                        radius: 10
                        color: "#2a2e38"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4
                            Text { text: "⚠️ Snapdragon 810 Thermal Governor"; font.bold: true; color: "#f39c12" }
                            Text {
                                text: "Controls CPU scaling to prevent overheating and core degradation."
                                font.pixelSize: 11
                                color: "#a0a5ad"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: ["interactive", "schedutil", "conservative", "powersave"]
                            delegate: Button {
                                Layout.fillWidth: true
                                text: modelData
                                highlighted: settingsView.governor === modelData
                                onClicked: {
                                    settingsView.governor = modelData;
                                    if (typeof systemBackend !== "undefined") {
                                        systemBackend.setCpuGovernor(modelData);
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: "#23262e"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "BLOD 4-Core Fail-Safe Mode"; font.bold: true; color: "#ffffff"; Layout.fillWidth: true }
                            Text { text: "Active (Cores 0-3 @ 1.55 GHz)"; font.bold: true; color: "#2ecc71" }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: "#23262e"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            Text { text: "SoC Core Temperature"; font.bold: true; color: "#ffffff"; Layout.fillWidth: true }
                            Text { text: settingsView.cpuTempStr; font.bold: true; color: "#f39c12" }
                        }
                    }
                }

                // --- BATTERY SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: settingsView.currentSection === "Battery"
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        radius: 12
                        color: "#23262e"

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "🔋 " + settingsView.batteryPercentStr + " Remaining"; font.bold: true; font.pixelSize: 22; color: "#3daee9"; Layout.alignment: Qt.AlignHCenter }
                            Text { text: "3450 mAh Li-Po Battery • " + settingsView.batteryStatusStr; font.pixelSize: 12; color: "#a0a5ad"; Layout.alignment: Qt.AlignHCenter }
                            Text { text: "System Uptime: " + settingsView.uptimeStr; font.pixelSize: 12; color: "#2ecc71"; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }
            }
        }
    }
}
