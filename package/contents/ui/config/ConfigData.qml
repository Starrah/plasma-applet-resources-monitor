import QtQuick 2.2
import QtQuick.Controls 2.12 as QtControls
import QtQuick.Layouts 1.1 as QtLayouts
import org.kde.kirigami 2.6 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import "../components" as RMComponents
import "../controls" as RMControls
import "../components/functions.js" as Functions

QtLayouts.ColumnLayout {
    id: dataPage

    signal configurationChanged

    readonly property var networkDialect: Functions.getNetworkDialectInfo(plasmoid.configuration.networkUnit)
    property double cfg_networkReceivingTotal: 0.0
    property double cfg_networkSendingTotal: 0.0
    property double cfg_diskReadTotal: 0.0
    property double cfg_diskWriteTotal: 0.0
    property alias cfg_gpuMemoryTotalCorrectionEnabled: gpuMemoryTotalCorrectionEnabled.checked
    property alias cfg_gpuMemoryTotalCorrectionValue: gpuMemoryTotalCorrectionValue.value
    property alias cfg_thresholdWarningCpuTemp: thresholdWarningCpuTemp.value
    property alias cfg_thresholdCriticalCpuTemp: thresholdCriticalCpuTemp.value
    property alias cfg_thresholdWarningMemory: thresholdWarningMemory.value
    property alias cfg_thresholdCriticalMemory: thresholdCriticalMemory.value
    property alias cfg_thresholdWarningGpuTemp: thresholdWarningGpuTemp.value
    property alias cfg_thresholdCriticalGpuTemp: thresholdCriticalGpuTemp.value

    readonly property var networkSpeedOptions: [
        {
            label: i18n("Custom"),
            value: -1,
        }, {
            label: "100 " + networkDialect.kiloChar + networkDialect.suffix,
            value: 100.0,
        }, {
            label: "1 M" + networkDialect.suffix,
            value: 1000.0,
        }, {
            label: "10 M" + networkDialect.suffix,
            value: 10000.0,
        }, {
            label: "100 M" + networkDialect.suffix,
            value: 100000.0,
        }, {
            label: "1 G" + networkDialect.suffix,
            value: 1000000.0,
        }, {
            label: "2.5 G" + networkDialect.suffix,
            value: 2500000.0,
        }, {
            label: "5 G" + networkDialect.suffix,
            value: 5000000.0,
        }, {
            label: "10 G" + networkDialect.suffix,
            value: 10000000.0,
        }
    ]

    readonly property var diskSpeedOptions: [
        {
            label: i18n("Custom"),
            value: -1,
        }, {
            label: "10 MiB/s",
            value: 10,
        }, {
            label: "100 MiB/s",
            value: 100,
        }, {
            label: "200 MiB/s",
            value: 200,
        }, {
            label: "500 MiB/s",
            value: 500,
        }, {
            label: "1000 MiB/s",
            value: 1000,
        }, {
            label: "2000 MiB/s",
            value: 2000,
        }, {
            label: "5000 MiB/s",
            value: 5000,
        }, {
            label: "10000 MiB/s",
            value: 10000,
        }
    ]

    // Detect network interfaces
    RMComponents.NetworkInterfaceDetector {
        id: networkInterfaces
    }

    // Tab bar
    PlasmaComponents.TabBar {
        id: bar

        PlasmaComponents.TabButton {
            tab: networkPage
            iconSource: "preferences-system-network"
            text: i18n("Network")
        }
        PlasmaComponents.TabButton {
            tab: gpuPage
            iconSource: "applications-graphics"
            text: i18n("GPU")
        }
        PlasmaComponents.TabButton {
            tab: diskPage
            iconSource: "drive-harddisk"
            text: i18n("Disk")
        }
        PlasmaComponents.TabButton {
            tab: thresholdPage
            iconSource: "dialog-warning"
            text: i18n("Thresholds")
        }
    }

    // Views
    PlasmaComponents.TabGroup {
        QtLayouts.Layout.fillWidth: true
        QtLayouts.Layout.fillHeight: true

        // Network
        Kirigami.FormLayout {
            id: networkPage
            wideMode: true

            // Network interfaces
            QtLayouts.GridLayout {
                Kirigami.FormData.label: i18n("Network interfaces:")
                QtLayouts.Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: networkInterfaces.model
                    QtControls.CheckBox {
                        readonly property string interfaceName: modelData
                        readonly property bool ignoredByDefault: {
                            return /^(docker|tun|tap)(\d+)/.test(interfaceName) // Ignore docker and tun/tap networks
                        }

                        text: interfaceName
                        checked: plasmoid.configuration.ignoredNetworkInterfaces.indexOf(interfaceName) == -1 && !ignoredByDefault
                        enabled: !ignoredByDefault

                        onClicked: {
                            var ignoredNetworkInterfaces = plasmoid.configuration.ignoredNetworkInterfaces.slice(0) // copy()
                            if (checked) {
                                // Checking, and thus removing from the ignoredNetworkInterfaces
                                var i = ignoredNetworkInterfaces.indexOf(interfaceName)
                                ignoredNetworkInterfaces.splice(i, 1)
                            } else {
                                // Unchecking, and thus adding to the ignoredNetworkInterfaces
                                ignoredNetworkInterfaces.push(interfaceName)
                            }

                            plasmoid.configuration.ignoredNetworkInterfaces = ignoredNetworkInterfaces
                            // To modify a StringList we need to manually trigger configurationChanged.
                            dataPage.configurationChanged()
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                height: Kirigami.Units.largeSpacing * 2
                color: "transparent"
            }

            PlasmaComponents.Label {
                text: i18n("Maximum transfer speed")
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
            }

            // Separator
            Rectangle {
                height: Kirigami.Units.largeSpacing
                color: "transparent"
            }

            // Receiving speed
            QtControls.ComboBox {
                id: networkReceivingTotal
                Kirigami.FormData.label: i18n("Receiving:")
                textRole: "label"
                model: networkSpeedOptions

                onCurrentIndexChanged: {
                    var current = model[currentIndex]
                    if (current && current.value !== -1) {
                        customNetworkReceivingTotal.valueReal = current.value / 1000
                    }
                }

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i]["value"] === plasmoid.configuration.networkReceivingTotal) {
                            networkReceivingTotal.currentIndex = i;
                            return
                        }
                    }

                    networkReceivingTotal.currentIndex = 0 // Custom
                }
            }
            RMControls.SpinBox {
                id: customNetworkReceivingTotal
                Kirigami.FormData.label: i18n("Custom value:")
                QtLayouts.Layout.fillWidth: true
                decimals: 3
                stepSize: 1
                minimumValue: 0.001
                visible: networkReceivingTotal.currentIndex === 0

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + " M" + networkDialect.suffix
                }

                onValueChanged: {
                    var newValue = valueReal * 1000
                    if (cfg_networkReceivingTotal !== newValue)  {
                        cfg_networkReceivingTotal = newValue
                        dataPage.configurationChanged()
                    }
                }
                Component.onCompleted: {
                    valueReal = parseFloat(plasmoid.configuration.networkReceivingTotal) / 1000
                }
            }

            // Separator
            Rectangle {
                height: Kirigami.Units.largeSpacing
                color: "transparent"
            }

            // Sending speed
            QtControls.ComboBox {
                id: networkSendingTotal
                Kirigami.FormData.label: i18n("Sending:")
                textRole: "label"
                model: networkSpeedOptions

                onCurrentIndexChanged: {
                    var current = model[currentIndex]
                    if (current && current.value !== -1) {
                        customNetworkSendingTotal.valueReal = current.value / 1000
                    }
                }

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i]["value"] === plasmoid.configuration.networkSendingTotal) {
                            networkSendingTotal.currentIndex = i;
                            return
                        }
                    }

                    networkSendingTotal.currentIndex = 0 // Custom
                }
            }
            RMControls.SpinBox {
                id: customNetworkSendingTotal
                Kirigami.FormData.label: i18n("Custom value:")
                QtLayouts.Layout.fillWidth: true
                decimals: 3
                stepSize: 1
                minimumValue: 0.001
                visible: networkSendingTotal.currentIndex === 0

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + " M" + networkDialect.suffix
                }

                 onValueChanged: {
                    var newValue = valueReal * 1000
                    if (cfg_networkSendingTotal !== newValue)  {
                        cfg_networkSendingTotal = newValue
                        dataPage.configurationChanged()
                    }
                }
                Component.onCompleted: {
                    valueReal = parseFloat(plasmoid.configuration.networkSendingTotal) / 1000
                }
            }
        }

        Kirigami.FormLayout {
            id: gpuPage
            wideMode: true

            QtControls.CheckBox {
                id: gpuMemoryTotalCorrectionEnabled
                text: i18n("GPU total VRAM correction")
            }

            RMControls.SpinBox {
                id: gpuMemoryTotalCorrectionValue
                Kirigami.FormData.label: i18n("GPU total VRAM")
                QtLayouts.Layout.fillWidth: true
                enabled: gpuMemoryTotalCorrectionEnabled.enabled

                textFromValue: function(value, locale) {
                    return value + " MiB"
                }
            }
        }

        // Disk
        Kirigami.FormLayout {
            id: diskPage
            wideMode: true

            PlasmaComponents.Label {
                text: i18n("Maximum transfer speed")
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
            }

            // Separator
            Rectangle {
                height: Kirigami.Units.largeSpacing
                color: "transparent"
            }

            // Receiving speed
            QtControls.ComboBox {
                id: diskReadTotal
                Kirigami.FormData.label: i18n("Read:")
                textRole: "label"
                model: diskSpeedOptions

                onCurrentIndexChanged: {
                    var current = model[currentIndex]
                    if (current && current.value !== -1) {
                        customDiskReadTotal.valueReal = current.value
                    }
                }

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i]["value"] === plasmoid.configuration.diskReadTotal) {
                            diskReadTotal.currentIndex = i;
                            return
                        }
                    }

                    diskReadTotal.currentIndex = 0 // Custom
                }
            }
            RMControls.SpinBox {
                id: customDiskReadTotal
                Kirigami.FormData.label: i18n("Custom value:")
                QtLayouts.Layout.fillWidth: true
                decimals: 3
                stepSize: 1
                minimumValue: 0.001
                visible: diskReadTotal.currentIndex === 0

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + " MiB/s"
                }

                onValueChanged: {
                    var newValue = valueReal
                    if (cfg_diskReadTotal !== newValue)  {
                        cfg_diskReadTotal = newValue
                        dataPage.configurationChanged()
                    }
                }
                Component.onCompleted: {
                    valueReal = parseFloat(plasmoid.configuration.diskReadTotal)
                }
            }

            // Separator
            Rectangle {
                height: Kirigami.Units.largeSpacing
                color: "transparent"
            }

            // Sending speed
            QtControls.ComboBox {
                id: diskWriteTotal
                Kirigami.FormData.label: i18n("Write:")
                textRole: "label"
                model: diskSpeedOptions

                onCurrentIndexChanged: {
                    var current = model[currentIndex]
                    if (current && current.value !== -1) {
                        customDiskWriteTotal.valueReal = current.value
                    }
                }

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i]["value"] === plasmoid.configuration.diskWriteTotal) {
                            diskWriteTotal.currentIndex = i;
                            return
                        }
                    }

                    diskWriteTotal.currentIndex = 0 // Custom
                }
            }
            RMControls.SpinBox {
                id: customdiskWriteTotal
                Kirigami.FormData.label: i18n("Custom value:")
                QtLayouts.Layout.fillWidth: true
                decimals: 3
                stepSize: 1
                minimumValue: 0.001
                visible: diskWriteTotal.currentIndex === 0

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + " MiB/s"
                }

                 onValueChanged: {
                    var newValue = valueReal
                    if (cfg_diskWriteTotal !== newValue)  {
                        cfg_diskWriteTotal = newValue
                        dataPage.configurationChanged()
                    }
                }
                Component.onCompleted: {
                    valueReal = parseFloat(plasmoid.configuration.diskWriteTotal)
                }
            }
        }

        Kirigami.FormLayout {
            id: thresholdPage
            wideMode: true

            QtLayouts.GridLayout {
                QtLayouts.Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                PlasmaComponents.Label {
                    text: i18n("Warning     ")
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                }
                PlasmaComponents.Label {
                    text: i18n("    Critical")
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                }
            }

            QtLayouts.GridLayout {
                Kirigami.FormData.label: i18n("CPU Temperature:")
                QtLayouts.Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                RMControls.SpinBox {
                    id: thresholdWarningCpuTemp
                    Kirigami.FormData.label: i18n("Warning")
                    QtLayouts.Layout.fillWidth: true

                    textFromValue: function(value, locale) {
                        return value + " °C"
                    }
                }
                RMControls.SpinBox {
                    id: thresholdCriticalCpuTemp
                    Kirigami.FormData.label: i18n("Critical")
                    QtLayouts.Layout.fillWidth: true

                    textFromValue: function(value, locale) {
                        return value + " °C"
                    }
                }
            }

            QtLayouts.GridLayout {
                Kirigami.FormData.label: i18n("Physical Memory Usage:")
                QtLayouts.Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                RMControls.SpinBox {
                    id: thresholdWarningMemory
                    Kirigami.FormData.label: i18n("Warning")
                    QtLayouts.Layout.fillWidth: true

                    textFromValue: function(value, locale) {
                        return value + " %"
                    }
                }
                RMControls.SpinBox {
                    id: thresholdCriticalMemory
                    Kirigami.FormData.label: i18n("Critical")
                    QtLayouts.Layout.fillWidth: true

                    textFromValue: function(value, locale) {
                        return value + " %"
                    }
                }
            }

            QtLayouts.GridLayout {
                Kirigami.FormData.label: i18n("GPU Temperature:")
                QtLayouts.Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                RMControls.SpinBox {
                    id: thresholdWarningGpuTemp
                    Kirigami.FormData.label: i18n("Warning")
                    QtLayouts.Layout.fillWidth: true

                    textFromValue: function(value, locale) {
                        return value + " °C"
                    }
                }
                RMControls.SpinBox {
                    id: thresholdCriticalGpuTemp
                    Kirigami.FormData.label: i18n("Critical")
                    QtLayouts.Layout.fillWidth: true

                    textFromValue: function(value, locale) {
                        return value + " °C"
                    }
                }
            }
        }
    }
}
