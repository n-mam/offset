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
            name: "fit", 
            icon: "qrc:/fit.png" 
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
            anchors.fill: parent
            border.color: borderColor
            implicitWidth: 220
            implicitHeight: 120            
            color: Qt.lighter(Material.background)
            ColumnLayout {
                spacing: 5
                anchors.margins: 5
                anchors.fill: parent
                layoutDirection: Qt.LeftToRight
                Label {
                    text: "Data Source"
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2
                    TextField {
                        id: source
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 36
                        placeholderText: "stream"
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2
                    Button {
                        text: "Stop"
                        onClicked: {
                            visualizer.stop_imu_visualization();                            
                            activePanel = ""
                        }
                    }
                    Button {
                        text: "Start"
                        onClicked: {
                            visualizer.start_imu_visualization(source.text);
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
