import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls

Item {

    id: root
    required property var visualizer
    property string activePanel: ""
    property string activeSubmenu: ""

    implicitWidth: column.implicitWidth + column.anchors.margins * 2
    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    x: parent ? parent.width - root.implicitWidth - 8 : 0
    y: parent ? (parent.height - root.implicitHeight)/2 : 0

    property var tools: [
        {
            name: "original",
            icon: "qrc:/cloud.png"
        },
        {
            name: "filter",
            icon: "qrc:/filter.png",
            sub: ["PMF", "RANSAC"]
        },
        {
            name: "colors",
            icon: "qrc:/colors.png",
            sub: ["original", "z-heatmap"]
        },
        {
            name: "sim",
            icon: "qrc:/sim.png",
            panel: true
        },
        {
            name: "debug",
            icon: "qrc:/debug.png"
        },
        {
            name: "fit",
            icon: "qrc:/fit.png"
        },
        {
            name: "open",
            icon: "qrc:/zoom.png"
        }
    ]

    ColumnLayout {
        id: column
        spacing: 16
        anchors.margins: 4
        anchors.centerIn: parent
        Repeater {
            model: root.tools
            Item {
                width: 30
                height: 30
                property var tool: modelData
                ToolButton {
                    id: btn
                    anchors.fill: parent
                    onClicked: {
                        if (tool.panel) {
                            activePanel = (activePanel === tool.name) ?
                                "" : tool.name
                            activeSubmenu = ""
                            return
                        }
                        if (tool.sub && tool.sub.length > 0) {
                            activeSubmenu =
                                activeSubmenu === tool.name ?
                                    "" : tool.name
                            activePanel = ""
                            return
                        }
                        activePanel = ""
                        activeSubmenu = ""
                        onToolClicked(tool.name)
                    }
                    background: Rectangle {
                        radius: 6
                        anchors.fill: parent
                        color: "#5d5d5d"
                    }
                    contentItem: Image {
                        width: 16
                        height: 16
                        source: tool.icon
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }
                }
                Popup {
                    id: popup
                    y: 0
                    modal: false
                    focus: false
                    x: -width - 8
                    visible: activeSubmenu === tool.name
                    background: Rectangle {
                        radius: 6
                        color: "#2b2b2b"
                    }
                    Column {
                        spacing: 6
                        padding: 6
                        Repeater {
                            model: tool.sub || []
                            ToolButton {
                                property string subItem: modelData
                                text: subItem
                                width: 100
                                onClicked: {
                                    onSubToolClicked(tool.name, subItem)
                                    activeSubmenu = ""
                                }
                                background: Rectangle {
                                    radius: 4
                                    color: "#444"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: settingsPanel

        radius: 8
        clip: true
        color: "#2b2b2b"

        anchors.right: column.left
        anchors.rightMargin: 12
        anchors.verticalCenter: column.verticalCenter

        implicitWidth: loader.item ? loader.item.implicitWidth : 0
        implicitHeight: loader.item ? loader.item.implicitHeight : 0

        width: activePanel === "" ? 0 : implicitWidth
        height: implicitHeight

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: 3
            sourceComponent: activePanel === "sim" ? simPanel : null
        }
    }

    Component {
        id: simPanel
        Rectangle {
            radius: 8
            border.width: 1
            border.color: borderColor
            color: Qt.lighter(Material.background)
            implicitWidth: 280
            implicitHeight: layout.implicitHeight + 20

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "IMU Source Data"
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextField {
                        id: source
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        placeholderText: "stream"
                        focus: true
                        onAccepted: {
                            visualizer.start_imu_visualization(text)
                            activePanel = ""
                        }
                    }
                    CheckBox {
                        id: debugCheckBox
                        text: "Log"
                        onCheckedChanged:
                            visualizer.control_imu_visualization("log", checked)
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 0
                    Label {
                        text: "kp_acc"
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                    }
                    Slider {
                        id: kp_acc
                        to: 5.0
                        from: 0.0
                        live: true
                        value: 2.0
                        stepSize: 0.1
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onValueChanged: {
                            visualizer.control_imu_visualization("kp_acc", value)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 36
                        text: kp_acc.value.toFixed(1)
                        font.family: "monospace"
                    }
                    Label {
                        text: "ki_acc"
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                    }
                    Slider {
                        id: ki_acc
                        to: 0.1
                        from: 0.0
                        live: true
                        value: 0.01
                        stepSize: 0.001
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onValueChanged: {
                            visualizer.control_imu_visualization("ki_acc", value)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 36
                        text: ki_acc.value.toFixed(3)
                        font.family: "monospace"
                    }
                    Label {
                        text: "kp_mag"
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                    }
                    Slider {
                        id: kp_mag
                        to: 5.0
                        from: 0.0
                        live: true
                        value: 2.0
                        stepSize: 0.1
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onValueChanged: {
                            visualizer.control_imu_visualization("kp_mag", value)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 36
                        text: kp_mag.value.toFixed(1)
                        font.family: "monospace"
                    }
                    Label {
                        text: "ki_mag"
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                    }
                    Slider {
                        id: ki_mag
                        to: 0.1
                        from: 0.0
                        live: true
                        value: 0.01
                        stepSize: 0.001
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onValueChanged: {
                            visualizer.control_imu_visualization("ki_mag", value)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 36
                        text: ki_mag.value.toFixed(3)
                        font.family: "monospace"
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Button {
                        text: "Start"
                        onClicked: {
                            visualizer.start_imu_visualization(source.text)
                            activePanel = ""
                        }
                    }
                    Button {
                        text: "Stop"
                        onClicked: {
                            visualizer.stop_imu_visualization()
                            activePanel = ""
                        }
                    }
                }
            }
        }
    }

    function onToolClicked(tool) {
        if (tool === "original") {
            visualizer.restore_base_pipeline();
        } else if (tool === "open") {
            fileDialog.open()
        } else if (tool === 'debug') {
            visualizer.toggle_debug_overlay();
        } else if (tool === "fit") {
            visualizer.fit_to_cloud();
        }
    }

    function onSubToolClicked(tool, subtool) {
        if (tool === "colors" && subtool === "z-heatmap") {
            visualizer.apply_scalar("z-heatmap")
        } else if (tool === "colors" && subtool === "original") {
            visualizer.apply_scalar("original")
        } else if (tool === "filter" && subtool === "PMF") {
            visualizer.elevation_filter_pmf()
        } else if (tool === "filter" && subtool === "RANSAC") {
            visualizer.elevation_filter_ransac()
        }
    }

    FileDialog {
        id: fileDialog
        title: "Load File"
        fileMode: FileDialog.OpenFile
        nameFilters: [ "All Files (*)" ]
        currentFolder: StandardPaths.writableLocation(StandardPaths.DesktopLocation)
        onAccepted: {
            visualizer.load_point_cloud(fileDialog.selectedFile)
        }
    }
}
