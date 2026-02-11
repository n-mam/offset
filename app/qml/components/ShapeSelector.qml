import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    modal: false
    closePolicy: Popup.NoAutoClose
    property string currentTool: "idle"

    property var tools: [
        { name: "idle", icon: "qrc:/idle.png"},
        { name: "wall", icon: "qrc:/wall.png" },
        { name: "door", icon: "qrc:/door.png" },
        { name: "window", icon: "qrc:/window.png" },
        { name: "dimension", icon: "qrc:/ruler.png" }
    ]

    ColumnLayout {
        id: column
        spacing: 16
        anchors.margins: 4
        anchors.centerIn: parent

        Repeater {
            model: root.tools
            ToolButton {
                checkable: true
                checked: root.currentTool === modelData.name
                onClicked: root.currentTool = modelData.name
                width: 30
                height: 30
                background: Rectangle {
                    anchors.fill: parent
                    radius: 6
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

    implicitWidth: column.implicitWidth + column.anchors.margins * 2
    implicitHeight: column.implicitHeight + column.anchors.margins * 2

    x: parent ? parent.width - root.implicitWidth - 8 : 0
    y: parent ? (parent.height - root.implicitHeight)/2 : 0
}
