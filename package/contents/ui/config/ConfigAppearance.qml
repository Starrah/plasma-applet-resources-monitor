import QtQuick 2.2
import QtQuick.Controls 2.12 as QtControls
import QtQuick.Layouts 1.1 as QtLayouts
import org.kde.kirigami 2.6 as Kirigami
import org.kde.plasma.components 2.0 as PlasmaComponents

import "../controls" as RMControls

QtLayouts.ColumnLayout {
    property alias cfg_verticalLayout: verticalLayout.checked
    property alias cfg_historyAmount: historyAmount.value
    property alias cfg_customGraphWidth: graphWidth.checked
    property alias cfg_graphWidth: graphWidth.value
    property alias cfg_customGraphHeight: graphHeight.checked
    property alias cfg_graphHeight: graphHeight.value
    property alias cfg_graphMargin: graphMargin.value
    property alias cfg_graphFillOpacity: graphFillOpacity.value

    property alias cfg_enableShadows: enableShadows.checked
    property alias cfg_fontScale: fontScale.value
    property string cfg_placement: ""
    property string cfg_displayment: ""

    property alias cfg_customTemperatureColor: temperatureColor.checked
    property alias cfg_temperatureColor: temperatureColor.value
    property alias cfg_customCpuColor: cpuColor.checked
    property alias cfg_cpuColor: cpuColor.value
    property alias cfg_customRamColor: ramColor.checked
    property alias cfg_ramColor: ramColor.value
    property alias cfg_customSwapColor: swapColor.checked
    property alias cfg_swapColor: swapColor.value
    property alias cfg_customSwapTextColor: swapTextColor.checked
    property alias cfg_swapTextColor: swapTextColor.value
    property alias cfg_customNetDownColor: netDownColor.checked
    property alias cfg_netDownColor: netDownColor.value
    property alias cfg_customNetUpColor: netUpColor.checked
    property alias cfg_netUpColor: netUpColor.value
    property alias cfg_customGpuColor: gpuColor.checked
    property alias cfg_gpuColor: gpuColor.value
    property alias cfg_customGpuMemoryColor: gpuMemoryColor.checked
    property alias cfg_gpuMemoryColor: gpuMemoryColor.value
    property alias cfg_customDiskReadColor: diskReadColor.checked
    property alias cfg_diskReadColor: diskReadColor.value
    property alias cfg_customDiskWriteColor: diskWriteColor.checked
    property alias cfg_diskWriteColor: diskWriteColor.value
    property alias cfg_customWarningColor: warningColor.checked
    property alias cfg_warningColor: warningColor.value
    property alias cfg_customCriticalColor: criticalColor.checked
    property alias cfg_criticalColor: criticalColor.value

    property color primaryColor: theme.highlightColor
    property color negativeColor: theme.negativeTextColor


    PlasmaComponents.TabBar {
        id: bar

        PlasmaComponents.TabButton {
            tab: graphPage
            text: i18n("Graph")
        }
        PlasmaComponents.TabButton {
            tab: textPage
            iconSource: "dialog-text-and-font"
            text: i18n("Text")
        }
        PlasmaComponents.TabButton {
            tab: colorsPage
            iconSource: "preferences-desktop-color"
            text: i18n("Colors")
        }
    }

    PlasmaComponents.TabGroup {
        QtLayouts.Layout.fillWidth: true
        QtLayouts.Layout.fillHeight: true

        // Graph
        Kirigami.FormLayout {
            id: graphPage
            wideMode: true

            QtControls.CheckBox {
                id: verticalLayout
                text: i18n("Vertical layout")
            }

            RMControls.SpinBox {
                id: historyAmount
                Kirigami.FormData.label: i18n("History amount:")
                QtLayouts.Layout.fillWidth: true
                from: 2
            }

            RMControls.CustomizableSize {
                id: graphWidth
                Kirigami.FormData.label: i18n("Width:")
                QtLayouts.Layout.fillWidth: true
                from: 1
                to: 1000
            }
            RMControls.CustomizableSize {
                id: graphHeight
                Kirigami.FormData.label: i18n("Height:")
                QtLayouts.Layout.fillWidth: true
                from: 1
                to: 1000
            }
            RMControls.SpinBox {
                id: graphMargin
                Kirigami.FormData.label: i18n("Margin:")
                QtLayouts.Layout.fillWidth: true
                from: 1
                to: 1000

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + " px"
                }
            }
            RMControls.SpinBox {
                id: graphFillOpacity
                Kirigami.FormData.label: i18n("Fill opacity:")
                QtLayouts.Layout.fillWidth: true
                from: 1
                to: 100

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + "%"
                }
            }
        }

        // Text
        Kirigami.FormLayout {
            id: textPage
            wideMode: true

            QtControls.CheckBox {
                id: enableShadows
                text: i18n("Drop shadows")
            }

            RMControls.SpinBox {
                id: fontScale
                Kirigami.FormData.label: i18n("Font scale:")
                QtLayouts.Layout.fillWidth: true
                from: 1
                to: 100

                textFromValue: function(value, locale) {
                    return valueToText(value, locale) + "%"
                }
            }

            QtControls.ComboBox {
                id: displayment
                Kirigami.FormData.label: i18n("Text displayment:")
                textRole: "label"
                model: [{
                    "label": i18n("Always"),
                    "name": "always"
                }, {
                    "label": i18n("On hover"),
                    "name": "hover"
                }, {
                    "label": i18n("Hints when hover"),
                    "name": "hover-hints"
                }]
                onCurrentIndexChanged: cfg_displayment = model[currentIndex]["name"]

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i]["name"] === plasmoid.configuration.displayment) {
                            displayment.currentIndex = i;
                        }
                    }
                }
            }

            QtControls.ComboBox {
                id: placement
                Kirigami.FormData.label: i18n("Placement:")
                textRole: "label"
                model: [{
                    "label": i18n("Top left"),
                    "name": "top-left"
                }, {
                    "label": i18n("Top right"),
                    "name": "top-right"
                }, {
                    "label": i18n("Bottom left"),
                    "name": "bottom-left"
                }, {
                    "label": i18n("Bottom right"),
                    "name": "bottom-right"
                }]
                onCurrentIndexChanged: cfg_placement = model[currentIndex]["name"]

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i]["name"] === plasmoid.configuration.placement) {
                            placement.currentIndex = i;
                        }
                    }
                }
            }
        }

        // Colors
        Kirigami.FormLayout {
            id: colorsPage

            RMControls.ColorSelector {
                id: temperatureColor
                Kirigami.FormData.label: i18n("Temperature text color:")

                dialogTitle: i18n("Choose text color for temperature text (when in normal status)")
                defaultColor: primaryColor
            }

            RMControls.ColorSelector {
                id: cpuColor
                Kirigami.FormData.label: i18n("CPU color:")

                dialogTitle: i18n("Choose CPU graph color")
                defaultColor: primaryColor
            }

            RMControls.ColorSelector {
                id: ramColor
                Kirigami.FormData.label: i18n("Memory color:")

                dialogTitle: i18n("Choose memory graph color")
                defaultColor: primaryColor
            }
            RMControls.ColorSelector {
                id: swapColor
                Kirigami.FormData.label: i18n("Swap color:")

                dialogTitle: i18n("Choose Swap graph color")
                defaultColor: negativeColor
            }
            RMControls.ColorSelector {
                id: swapTextColor
                Kirigami.FormData.label: i18n("Swap Text color:")

                dialogTitle: i18n("Choose Swap text color")
                defaultColor: primaryColor
            }

            RMControls.ColorSelector {
                id: netDownColor
                Kirigami.FormData.label: i18n("Network receiving color:")

                dialogTitle: i18n("Choose network receiving graph color")
                defaultColor: primaryColor
            }
            RMControls.ColorSelector {
                id: netUpColor
                Kirigami.FormData.label: i18n("Network sending color:")

                dialogTitle: i18n("Choose network sending graph color")
                defaultColor: negativeColor
            }
            RMControls.ColorSelector {
                id: gpuColor
                Kirigami.FormData.label: i18n("GPU color:")

                dialogTitle: i18n("Choose GPU usage graph color")
                defaultColor: primaryColor
            }
            RMControls.ColorSelector {
                id: gpuMemoryColor
                Kirigami.FormData.label: i18n("GPU memory color:")

                dialogTitle: i18n("Choose GPU memory graph color")
                defaultColor: negativeColor
            }
            RMControls.ColorSelector {
                id: diskReadColor
                Kirigami.FormData.label: i18n("Disk read color:")

                dialogTitle: i18n("Choose disk read graph color")
                defaultColor: primaryColor
            }
            RMControls.ColorSelector {
                id: diskWriteColor
                Kirigami.FormData.label: i18n("Disk write color:")

                dialogTitle: i18n("Choose disk write graph color")
                defaultColor: negativeColor
            }

            RMControls.ColorSelector {
                id: warningColor
                Kirigami.FormData.label: i18n("Warning text color:")

                dialogTitle: i18n("Choose text color when the value is in warning status")
                defaultColor: "#f6cd00"
            }
            RMControls.ColorSelector {
                id: criticalColor
                Kirigami.FormData.label: i18n("Critical text color:")

                dialogTitle: i18n("Choose text color when the value is in critical status")
                defaultColor: "#da4453"
            }
        }
    }
}
