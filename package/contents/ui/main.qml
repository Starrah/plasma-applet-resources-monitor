/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kio 1.0 as Kio
import org.kde.kcoreaddons 1.0 as KCoreAddons

import org.kde.ksysguard.sensors 1.0 as Sensors

import "./components" as RMComponents
import "./components/functions.js" as Functions

Item {
    id: main

    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)
    property color primaryColor: theme.highlightColor
    property color negativeColor: theme.negativeTextColor

    // Settings properties
    property bool verticalLayout: plasmoid.configuration.verticalLayout
    property string actionService: plasmoid.configuration.actionService

    property bool showCpuMonitor: plasmoid.configuration.showCpuMonitor
    property bool showClock: plasmoid.configuration.showClock
    property bool showCpuTemperature: plasmoid.configuration.showCpuTemperature
    property bool showRamMonitor: plasmoid.configuration.showRamMonitor
    property bool showMemoryInPercent: plasmoid.configuration.memoryInPercent
    property bool showSwapGraph: plasmoid.configuration.memorySwapGraph
    property bool showNetMonitor: plasmoid.configuration.showNetMonitor
    property bool showGpuMonitor: plasmoid.configuration.showGpuMonitor
    property bool gpuMemoryInPercent: plasmoid.configuration.gpuMemoryInPercent
    property bool gpuMemoryGraph: plasmoid.configuration.gpuMemoryGraph
    property bool showGpuTemperature: plasmoid.configuration.showGpuTemperature
    property bool showDiskMonitor: plasmoid.configuration.showDiskMonitor

    property double diskReadTotal: plasmoid.configuration.diskReadTotal
    property double diskWriteTotal: plasmoid.configuration.diskWriteTotal

    // Colors settings properties
    property double fontScale: (plasmoid.configuration.fontScale / 100)
    property color cpuColor: plasmoid.configuration.customCpuColor ? plasmoid.configuration.cpuColor : primaryColor
    property color ramColor: plasmoid.configuration.customRamColor ? plasmoid.configuration.ramColor : primaryColor
    property color swapColor: plasmoid.configuration.customSwapColor ? plasmoid.configuration.swapColor : negativeColor
    property color swapTextColor: plasmoid.configuration.customSwapTextColor ? plasmoid.configuration.swapTextColor : primaryColor
    property color netDownColor: plasmoid.configuration.customNetDownColor ? plasmoid.configuration.netDownColor : primaryColor
    property color netUpColor: plasmoid.configuration.customNetUpColor ? plasmoid.configuration.netUpColor : negativeColor
    property color gpuColor: plasmoid.configuration.customGpuColor ? plasmoid.configuration.gpuColor : primaryColor
    property color gpuMemoryColor: plasmoid.configuration.customGpuMemoryColor ? plasmoid.configuration.gpuMemoryColor : negativeColor
    property color diskReadColor: plasmoid.configuration.customDiskReadColor ? plasmoid.configuration.diskReadColor : primaryColor
    property color diskWriteColor: plasmoid.configuration.customDiskWriteColor ? plasmoid.configuration.diskWriteColor : negativeColor
    readonly property color temperatureColor: plasmoid.configuration.customTemperatureColor ? plasmoid.configuration.temperatureColor : primaryColor
    readonly property color warningColor: plasmoid.configuration.customWarningColor ? plasmoid.configuration.warningColor : "#f6cd00"
    readonly property color criticalColor: plasmoid.configuration.customCriticalColor ? plasmoid.configuration.criticalColor : "#da4453"

    property int thresholdWarningCpuTemp: plasmoid.configuration.thresholdWarningCpuTemp
    property int thresholdCriticalCpuTemp: plasmoid.configuration.thresholdCriticalCpuTemp
    property int thresholdWarningMemory: plasmoid.configuration.thresholdWarningMemory
    property int thresholdCriticalMemory: plasmoid.configuration.thresholdCriticalMemory
    property int thresholdWarningGpuTemp: plasmoid.configuration.thresholdWarningGpuTemp
    property int thresholdCriticalGpuTemp: plasmoid.configuration.thresholdCriticalGpuTemp

    // Component properties
    property int containerCount: (showCpuMonitor?1:0) + (showRamMonitor?1:0) + (showNetMonitor?1:0) + (showGpuMonitor?1:0) + (showDiskMonitor?1:0)
    property int itemMargin: plasmoid.configuration.graphMargin
    property double parentWidth: parent === null ? 0 : parent.width
    property double parentHeight: parent === null ? 0 : parent.height
    property double initWidth:  vertical ? (verticalLayout ? parentWidth : (parentWidth - itemMargin) / 2) : (verticalLayout ? (parentHeight - itemMargin) / 2 : parentHeight)
    property double itemWidth: plasmoid.configuration.customGraphWidth ? plasmoid.configuration.graphWidth : (initWidth * (verticalLayout ? 1 : 1.5))
    property double itemHeight: plasmoid.configuration.customGraphHeight ? plasmoid.configuration.graphHeight : initWidth
    property double fontPixelSize: verticalLayout ? (itemHeight / 1.4 * fontScale) : (itemHeight * fontScale)
    property double widgetWidth: !verticalLayout ? (itemWidth*containerCount + itemMargin*containerCount) : itemWidth
    property double widgetHeight: verticalLayout ? (itemHeight*containerCount + itemMargin*containerCount) : itemHeight

    Layout.preferredWidth: widgetWidth
    Layout.maximumWidth: widgetWidth
    Layout.preferredHeight: widgetHeight
    Layout.maximumHeight: widgetHeight

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    anchors.fill: parent

    Kio.KRun {
        id: kRun
    }

    // Bind settigns change
    onFontPixelSizeChanged: {
        for (var monitor of [cpuGraph, ramGraph, netGraph, gpuGraph, diskGraph]) {
            monitor.firstLineLabel.font.pixelSize = fontPixelSize
            monitor.secondLineLabel.font.pixelSize = fontPixelSize
            if (monitor.firstLineLeftLabel) monitor.firstLineLeftLabel.font.pixelSize = fontPixelSize
        }
    }

    onShowClockChanged: {
        if (!showClock) {
            cpuGraph.secondLineLabel.visible = false
        }
        if (!showCpuTemperature) {
            cpuGraph.firstLineLeftLabel.visible = false
        }
    }

    onShowMemoryInPercentChanged: {
        if (!(ramGraph.maxMemory[0] >= 0 && ramGraph.maxMemory[1] >= 0)) {
            return
        }

        if (showMemoryInPercent) {
            ramGraph.uplimits = [100,100]
        } else {
            ramGraph.uplimits = ramGraph.maxMemory
        }
        ramGraph.updateSensors()
    }

    onShowSwapGraphChanged: {
        if (ramGraph.maxMemory[0] >= 0 && ramGraph.maxMemory[1] >= 0) {
            ramGraph.updateSensors()
        }
    }

    onThresholdWarningMemoryChanged: {
        maxMemoryQueryModel.enabled = true
    }
    onThresholdCriticalMemoryChanged: {
        maxMemoryQueryModel.enabled = true
    }

    onGpuMemoryInPercentChanged: {
        if (!(gpuGraph.maxGpuValue >= 0)) {
            return
        }

        if (gpuMemoryInPercent) {
            gpuGraph.uplimits = [100,100]
        } else {
            gpuGraph.uplimits = [100, gpuGraph.maxGpuValue]
        }
        gpuGraph.updateSensors()
    }

    onGpuMemoryGraphChanged: {
        if (gpuGraph.maxGpuValue >= 0) {
            gpuGraph.updateSensors()
        }
    }

    onDiskReadTotalChanged: {
        diskGraph.uplimits = [diskReadTotal * (1024 * 1024), diskWriteTotal * (1024 * 1024)]
    }

    onDiskWriteTotalChanged: {
        diskGraph.uplimits = [diskReadTotal * (1024 * 1024), diskWriteTotal * (1024 * 1024)]
    }

    function keepInteger(str) {
        var r = str.match(/^([.\d]*)(.*)/)
        if (!(r && r[1])) return ""
        return Math.round(Number(r[1])) + r[2]
    }

    // Graphs
    RMComponents.SensorGraph {
        id: cpuGraph
        sensors: ["cpu/all/usage"]
        colors: [cpuColor]

        visible: showCpuMonitor
        width: itemWidth
        height: itemHeight

        label: "CPU"
        labelColor: cpuColor
        secondLabel: showClock ? i18n("⏲ Clock") : ""
        hasFirstLeftLabel: showCpuTemperature
        firstLeftLabel: showCpuTemperature ? "🌡️" : ""

        yRange {
            from: 0
            to: 100
        }

        function getCpuTempColor(value) {
            if (value >= thresholdCriticalCpuTemp) return criticalColor
            else if (value >= thresholdWarningCpuTemp) return warningColor
            else return temperatureColor
        }

        // Display first core frequency
        onDataTick: {
            if (canSeeValue(0) && showCpuTemperature) {
                firstLineLeftLabel.text = keepInteger(cpuTempSensor.formattedValue)
                firstLineLeftLabel.color = getCpuTempColor(cpuTempSensor.value)
            }
            if (canSeeValue(1)) {
                secondLineLabel.text = cpuFrequencySensor.getFormattedValue()
                secondLineLabel.visible = true
            }
        }
        RMComponents.CpuFrequency {
            id: cpuFrequencySensor
            enabled: showClock
            agregator: "average"
        }
        Sensors.Sensor {
            id: cpuTempSensor
            enabled: showCpuTemperature
            sensorId: "cpu/cpu0/temperature"
        }
        onShowValueWhenMouseMove: {
            if (showCpuTemperature) {
                firstLineLeftLabel.text = keepInteger(cpuTempSensor.formattedValue)
                firstLineLeftLabel.color = getCpuTempColor(cpuTempSensor.value)
            }
            secondLineLabel.text = cpuFrequencySensor.formattedValue
            secondLineLabel.visible = true
        }

        function canSeeValue(column) {
            if (column === 1 && !showClock) {
                return false
            }

            return textContainer.valueVisible
        }
    }

    RMComponents.TwoSensorGraph {
        id: ramGraph
        colors: [ramColor, swapColor]
        secondLabelWhenZero: false
        textColors: [theme.textColor, swapTextColor]

        visible: showRamMonitor
        width: itemWidth
        height: itemHeight
        anchors.left: parent.left
        anchors.leftMargin: !verticalLayout ? (showCpuMonitor?1:0) * (itemWidth + itemMargin) : 0
        anchors.top: parent.top
        anchors.topMargin: verticalLayout ? (showCpuMonitor?1:0) * (itemWidth + itemMargin) : 0

        label: "RAM"
        labelColor: ramColor
        secondLabel: showSwapGraph ? "Swap" : ""
        secondLabelColor: swapColor

        // Get max y of graph
        property var maxMemory: [-1, -1]
        Sensors.SensorDataModel {
            id: maxMemoryQueryModel
            sensors: ["memory/physical/total", "memory/swap/total"]
            enabled: true

            onDataChanged: {
                var value = parseInt(data(topLeft, Sensors.SensorDataModel.Value))
                if (!isNaN(value) && value !== -1) ramGraph.maxMemory[topLeft.column] = value
                if (ramGraph.maxMemory[0] >= 0 && ramGraph.maxMemory[1] >= 0) {
                    enabled = false
                    if (!showMemoryInPercent) {
                        ramGraph.uplimits = ramGraph.maxMemory
                        ramGraph.thresholds[0] = [ramGraph.maxMemory[0] * (thresholdWarningMemory / 100.0), ramGraph.maxMemory[0] * (thresholdCriticalMemory / 100.0)]
                    } else {
                        ramGraph.uplimits = [100, 100]
                        ramGraph.thresholds[0] = [thresholdWarningMemory, thresholdCriticalMemory]
                    }
                    ramGraph.updateSensors()
                }
            }
        }

        function updateSensors() {
            var suffix = showMemoryInPercent ? "Percent" : ""

            if (showSwapGraph) {
                sensors = ["memory/physical/used" + suffix, "memory/swap/used" + suffix]
            } else {
                sensors = ["memory/physical/used" + suffix]
            }
        }
    }

    RMComponents.NetworkGraph {
        id: netGraph

        colors: [netDownColor, netUpColor]

        visible: showNetMonitor
        width: itemWidth
        height: itemHeight
        anchors.left: parent.left
        anchors.leftMargin: !verticalLayout ? ((showCpuMonitor?1:0) + (showRamMonitor?1:0)) * (itemWidth + itemMargin) : 0
        anchors.top: parent.top
        anchors.topMargin: verticalLayout ? ((showCpuMonitor?1:0) + (showRamMonitor?1:0)) * (itemWidth + itemMargin) : 0

        label: i18n("⇘ Down")
        labelColor: netDownColor
        secondLabel: i18n("⇗ Up")
        secondLabelColor: netUpColor
    }

    RMComponents.TwoSensorGraph {
        id: gpuGraph
        colors: [gpuColor, gpuMemoryColor]
        secondLabelWhenZero: true
        hasFirstLeftLabel: true

        visible: showGpuMonitor
        width: itemWidth
        height: itemHeight
        anchors.left: parent.left
        anchors.leftMargin: !verticalLayout ? ((showCpuMonitor?1:0) + (showRamMonitor?1:0) + (showNetMonitor?1:0)) * (itemWidth + itemMargin) : 0
        anchors.top: parent.top
        anchors.topMargin: verticalLayout ? ((showCpuMonitor?1:0) + (showRamMonitor?1:0) + (showNetMonitor?1:0)) * (itemWidth + itemMargin) : 0

        label: "GPU"
        labelColor: gpuColor
        secondLabel: gpuMemoryGraph ? "VRAM" : ""
        secondLabelColor: gpuMemoryColor
        firstLeftLabel: showGpuTemperature ? "🌡️" : ""

        // Get max y of graph
        property var maxGpuValue: -1
        Sensors.SensorDataModel {
            id: maxGpuValueQueryModel
            sensors: ["gpu/gpu0/totalVram"]
            enabled: true

            onDataChanged: {
                var value = parseInt(data(topLeft, Sensors.SensorDataModel.Value))
                if (!isNaN(value) && value !== -1) gpuGraph.maxGpuValue = value
                if (gpuGraph.maxGpuValue >= 0) {
                    enabled = false
                    if (!gpuMemoryInPercent) {
                        gpuGraph.uplimits = [100, gpuGraph.maxGpuValue]
                    } else {
                        gpuGraph.uplimits = [100, 100]
                    }
                    gpuGraph.updateSensors()
                }
            }
        }

        function updateSensors() {
            sensors = ["gpu/gpu0/usage", "gpu/gpu0/usedVram"]
            gpuGraph.showPercentage = [false, gpuMemoryInPercent]
        }
        function getGpuTempColor(value) {
            if (value >= thresholdCriticalGpuTemp) return criticalColor
            else if (value >= thresholdWarningGpuTemp) return warningColor
            else return temperatureColor
        }

        readonly property var _the_dialect: {"name": "kibibyte", "suffix": "iB", "kiloChar": "K", "multiplier": 1024}
        Sensors.Sensor {
            id: gpuTempSensor
            enabled: showGpuTemperature
            sensorId: "gpu/gpu0/temperature"
        }
        onDataTick: {
            if (canSeeValue(0) && showGpuTemperature) {
                firstLineLeftLabel.text = keepInteger(gpuTempSensor.formattedValue)
                firstLineLeftLabel.color = getGpuTempColor(gpuTempSensor.value)
            }
        }
        onShowValueWhenMouseMove: {
            if (showGpuTemperature) {
                firstLineLeftLabel.text = keepInteger(gpuTempSensor.formattedValue)
                firstLineLeftLabel.color = getGpuTempColor(gpuTempSensor.value)
            }
        }
    }

    RMComponents.TwoSensorGraph {
        id: diskGraph
        colors: [diskReadColor, diskWriteColor]
        secondLabelWhenZero: true

        visible: showDiskMonitor
        width: itemWidth
        height: itemHeight
        anchors.left: parent.left
        anchors.leftMargin: !verticalLayout ? ((showCpuMonitor?1:0) + (showRamMonitor?1:0) + (showNetMonitor?1:0) + (showGpuMonitor?1:0)) * (itemWidth + itemMargin) : 0
        anchors.top: parent.top
        anchors.topMargin: verticalLayout ? ((showCpuMonitor?1:0) + (showRamMonitor?1:0) + (showNetMonitor?1:0) + (showGpuMonitor?1:0)) * (itemWidth + itemMargin) : 0

        label: "Read"
        labelColor: diskReadColor
        secondLabel: "Write"
        secondLabelColor: diskWriteColor

        uplimits: [diskReadTotal * (1024 * 1024), diskWriteTotal * (1024 * 1024)]
        sensors: ["disk/all/read", "disk/all/write"]
    }

    // Click action
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            kRun.openService(actionService)
        }
    }
}
