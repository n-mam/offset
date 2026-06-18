import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    required property var visualizer
    property string activeSubmenu: ""

    property var tools: [
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
                ToolButton {
                    id: btn
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.sub) {
                            activeSubmenu = (activeSubmenu === modelData.name) ? 
                                "" : modelData.name
                        } else {
                            onToolClicked(modelData.name)
                        }
                    }
                    background: Rectangle {
                        radius: 6
                        anchors.fill: parent
                        color: "#5d5d5d"
                    }
                    contentItem: Image {
                        source: modelData.icon
                        width: 16
                        height: 16
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
                    visible: activeSubmenu === modelData.name
                    background: Rectangle {
                        radius: 6
                        color: "#2b2b2b"
                    }
                    Column {
                        spacing: 6
                        padding: 6
                        Repeater {
                            model: modelData.sub || []
                            ToolButton {
                                text: modelData
                                width: 100
                                onClicked: {
                                    onSubToolClicked(modelData)
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

    function onToolClicked(tool) {
        if (tool === "open") {
            fileDialog.open()
        } else if (tool === 'debug') {
            visualizer.toggle_debug_overlay();
        } else if (tool === "fit") {
            visualizer.fit_to_cloud();
        }
    }

    function onSubToolClicked(subtool) {
        if (subtool === "z-heatmap") {
            visualizer.apply_scalar("z-heatmap")
        } else if (subtool === "original") {
            visualizer.apply_scalar("original")
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

    implicitWidth: column.implicitWidth + column.anchors.margins * 2
    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    x: parent ? parent.width - root.implicitWidth - 8 : 0
    y: parent ? (parent.height - root.implicitHeight)/2 : 0
}
