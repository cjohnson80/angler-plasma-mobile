import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: weatherRoot
    color: "#181b20"

    signal closeRequested()

    property string cityName: "Denver"
    property string currentTempF: "72°"
    property string currentTempC: "22°"
    property string conditionText: "Sunny"
    property string humidityText: "35%"
    property string windText: "10 km/h"
    property string lastUpdated: "Just now"
    property bool isLive: true

    Component.onCompleted: {
        fetchWeather();
    }

    function fetchWeather() {
        if (typeof systemBackend !== "undefined") {
            try {
                var res = JSON.parse(systemBackend.getWeather(cityInputField.text.trim() || weatherRoot.cityName));
                weatherRoot.cityName = res.city;
                weatherRoot.currentTempF = res.temp_f + "°F";
                weatherRoot.currentTempC = res.temp_c + "°C";
                weatherRoot.conditionText = res.condition;
                weatherRoot.humidityText = res.humidity + "%";
                weatherRoot.windText = res.wind_speed + " km/h";
                weatherRoot.lastUpdated = res.updated_at;
                weatherRoot.isLive = res.is_live;
            } catch (e) {
                console.log("Error fetching weather:", e);
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
                    text: "⛅ Weather"
                    font.bold: true
                    font.pixelSize: 15
                    color: "#fcfcfc"
                    Layout.fillWidth: true
                }

                Button {
                    text: "🔄"
                    flat: true
                    onClicked: weatherRoot.fetchWeather()
                }

                Button {
                    text: "✕"
                    flat: true
                    onClicked: weatherRoot.closeRequested()
                }
            }
        }

        // City Search / Switcher
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "#23262e"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                TextField {
                    id: cityInputField
                    Layout.fillWidth: true
                    text: weatherRoot.cityName
                    placeholderText: "Enter city name..."
                    color: "#ffffff"
                    onAccepted: weatherRoot.fetchWeather()
                }

                Button {
                    text: "Search"
                    highlighted: true
                    onClicked: weatherRoot.fetchWeather()
                }
            }
        }

        // Current Weather Hero Display
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1a2a3a" }
                GradientStop { position: 1.0; color: "#12161c" }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: weatherRoot.cityName
                    font.bold: true
                    font.pixelSize: 28
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: weatherRoot.currentTempF
                    font.bold: true
                    font.pixelSize: 64
                    color: "#3daee9"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: weatherRoot.conditionText + " (" + weatherRoot.currentTempC + ")"
                    font.pixelSize: 18
                    color: "#fcfcfc"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 280
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                // Weather Metrics Row
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    ColumnLayout {
                        spacing: 2
                        Text { text: "💧 Humidity"; font.pixelSize: 11; color: "#a0a5ad"; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherRoot.humidityText; font.bold: true; font.pixelSize: 14; color: "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text { text: "💨 Wind"; font.pixelSize: 11; color: "#a0a5ad"; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherRoot.windText; font.bold: true; font.pixelSize: 14; color: "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text { text: "📡 Source"; font.pixelSize: 11; color: "#a0a5ad"; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherRoot.isLive ? "Live API" : "Cached"; font.bold: true; font.pixelSize: 14; color: weatherRoot.isLive ? "#2ecc71" : "#f39c12"; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Text {
                    Layout.topMargin: 16
                    text: "Updated: " + weatherRoot.lastUpdated
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.4)
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
