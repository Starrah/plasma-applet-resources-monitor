import QtQuick 2.9
import QtGraphicalEffects 1.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.quickcharts 1.0 as Charts

import "./" as RMComponents
import "./functions.js" as Functions

Item {
	id: chart

    signal dataTick()
    signal showValueWhenMouseMove()

    readonly property alias sensorsModel: sensorsModel
    property var sensors: []
    property var uplimits: [100, 100]
    property var thresholds: [undefined, undefined]
    property var textColors: [theme.textColor, theme.textColor]
    property var showPercentage: [false, false]

    // Aliases
    readonly property alias textContainer: textContainer
    property alias label: textContainer.label
    property alias labelColor: textContainer.labelColor
    property alias firstLeftLabel: textContainer.firstLeftLabel
    property alias firstLeftLabelColor: textContainer.firstLeftLabelColor
    property alias hasFirstLeftLabel: textContainer.hasFirstLeftLabel
    property alias secondLabel: textContainer.secondLabel
    property alias secondLabelColor: textContainer.secondLabelColor
    readonly property alias firstLineLabel: textContainer.firstLineLabel
    readonly property alias firstLineLeftLabel: textContainer.firstLineLeftLabel
    readonly property alias secondLineLabel: textContainer.secondLineLabel

    // Graph properties
    readonly property int historyAmount: plasmoid.configuration.historyAmount
    readonly property int interval: plasmoid.configuration.updateInterval * 1000
    readonly property color warningColor: plasmoid.configuration.customWarningColor ? plasmoid.configuration.warningColor : "#f6cd00"
    readonly property color criticalColor: plasmoid.configuration.customCriticalColor ? plasmoid.configuration.criticalColor : "#da4453"
    property var colors: [theme.highlightColor, theme.textColor]
    property var thresholdColors: [warningColor, criticalColor]

    // Text properties
    property bool secondLabelWhenZero: true

    onSensorsChanged: sensorsModel._updateSensors()

    onUplimitsChanged: {
        firstChart.yRange.to = uplimits[0]
        secondChart.yRange.to = uplimits[1]
    }

    onIntervalChanged: _clearHistory()

    // Graphs
    Charts.LineChart {
        id: secondChart
        anchors.fill: parent

        direction: Charts.XYChart.ZeroAtEnd
        fillOpacity: plasmoid.configuration.graphFillOpacity / 100
        smooth: true

        yRange {
            from: 0
            to: 100
            automatic: false
        }

        colorSource: Charts.SingleValueSource { value: colors[1] }
        valueSources: [
            Charts.HistoryProxySource {
                id: secondChartHistory

                source: Charts.SingleValueSource {
                    id: secondChartSource
                }
                interval: chart.visible ? chart.interval : 0
                maximumHistory: chart.interval > 0 ? (chart.historyAmount * 1000) / chart.interval : 0
                fillMode: Charts.HistoryProxySource.FillFromStart

                onDataChanged: _dataTick()
            }
        ]
    }
    Charts.LineChart {
        id: firstChart
        anchors.fill: parent

        direction: Charts.XYChart.ZeroAtEnd
        fillOpacity: plasmoid.configuration.graphFillOpacity / 100
        smooth: true

        yRange {
            from: 0
            to: 100
            automatic: false
        }

        colorSource: Charts.SingleValueSource { value: colors[0] }
        valueSources: [
            Charts.HistoryProxySource {
                id: firstChartHistory

                source: Charts.SingleValueSource {
                    id: firstChartSource
                }
                interval: chart.visible ? chart.interval : 0
                maximumHistory: chart.interval > 0 ? (chart.historyAmount * 1000) / chart.interval : 0
                fillMode: Charts.HistoryProxySource.FillFromStart
            }
        ]
    }

    // Labels
    RMComponents.GraphText {
        id: textContainer
        anchors.fill: parent

        onShowValueInLabel: _showValueInLabel()
    }

    // Graph data
    Instantiator {
        id: sensorsModel
        active: chart.visible
        delegate: Sensors.Sensor {
            id: sensor
            sensorId: modelData
            updateRateLimit: chart.interval
        }

        function _updateSensors() {
            model = sensors
            _clearHistory()
        }
        function getData(index) {
            var object = objectAt(index)
            if (!object) return;
            return { value: object.value, formattedValue: object.formattedValue, sensorId: object.sensorId }
        }
    }
    onVisibleChanged: sensorsModel._updateSensors()

    property var sensorData1
    property var sensorData2

    function _updateData(index, data) {
        var value = data && data.value

        // Update label
        if (index === 0) { // is first line
            firstLineLabel.visible = true
            firstLineLabel.color = textColors[0]
            if (typeof value === 'undefined') {
                firstLineLabel.text = '...'
            } else {
                firstLineLabel.text = data.formattedValue
                if (showPercentage[0]) {
                    firstLineLabel.text = (data.value / data.uplimits[0]) + " %"
                }
                if (thresholds[0]) {
                    if (data.value >= thresholds[0][1]) firstLineLabel.color = thresholdColors[1]
                    else if (data.value >= thresholds[0][0]) firstLineLabel.color = thresholdColors[0]
                }
            }
        } else if (index === 1) { // is second line
            secondLineLabel.visible = secondLabelWhenZero
            secondLineLabel.color = textColors[1]
            if (typeof value === 'undefined') {
                secondLineLabel.text = '...'
            } else {
                secondLineLabel.text = data.formattedValue
                if (showPercentage[1]) {
                    firstLineLabel.text = (data.value / data.uplimits[1]) + " %"
                }
                secondLineLabel.visible = secondLineLabel.visible || data.value !== 0
                if (thresholds[1]) {
                    if (data.value >= thresholds[1][1]) secondLineLabel.color = thresholdColors[1]
                    else if (data.value >= thresholds[1][0]) secondLineLabel.color = thresholdColors[0]
                }
            }
        }
    }

    function _dataTick() {
        var sensorsLength = sensorsModel.model.length

        // Set default text when doesn't have sensors
        if (sensorsLength === 0) {
            if (canSeeValue(0)) _updateData(0, undefined)
            if (canSeeValue(1)) _updateData(1, undefined)
            return
        }

        chart.sensorData1 = sensorsModel.getData(0)
        chart.sensorData2 = sensorsModel.getData(1)

        // Update values
        if (chart.sensorData1) firstChartSource.value = chart.sensorData1.value
        if (chart.sensorData2) secondChartSource.value = chart.sensorData2.value

        // Update labels
        if (canSeeValue(0)) _updateData(0, chart.sensorData1)
        if (canSeeValue(1)) _updateData(1, chart.sensorData2)

        // Emit signal
        chart.dataTick()
    }

    // Utils functions
    function canSeeValue(column) {
        return textContainer.valueVisible
    }

    function _showValueInLabel() {
        _updateData(0, chart.sensorData1)
        _updateData(1, chart.sensorData2)
        chart.showValueWhenMouseMove()
    }

    function _clearHistory() {
        firstChartHistory.clear()
        secondChartHistory.clear()
    }
}
