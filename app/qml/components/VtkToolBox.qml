import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    required property var visualizer

    property var tools: [
        { name: "ror", icon: "qrc:/radius.png"},
        { name: "open", icon: "qrc:/zoom.png"}
    ]

    ColumnLayout {
        id: column
        spacing: 16
        anchors.margins: 4
        anchors.centerIn: parent

        Repeater {
            model: root.tools
            ToolButton {
                width: 30
                height: 30
                checkable: false
                onClicked: onToolClicked(modelData.name)
                background: Rectangle {
                    radius: 6
                    anchors.fill: parent
                    color: checked ? "#4285F4" : "#5d5d5d"
                }
                contentItem: Image {
                    source: modelData.icon
                    width: 16
                    height: 16
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }

    function onToolClicked(tool) {
        if (tool === "open") {
            fileDialog.open()
        } else if (tool === 'ror') {
            visualizer.radius_outlier_removal();
        }
    }

    FileDialog {
        id: fileDialog
        title: "Load File"
        fileMode: FileDialog.OpenFile
        nameFilters: [ "All Files (*)" ]
        currentFolder: StandardPaths.writableLocation(StandardPaths.DesktopLocation)
        onAccepted: {
            visualizer.load_point_cloud(fileDialog.currentFile)
        }
    }

    implicitWidth: column.implicitWidth + column.anchors.margins * 2
    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    x: parent ? parent.width - root.implicitWidth - 8 : 0
    y: parent ? (parent.height - root.implicitHeight)/2 : 0
}
