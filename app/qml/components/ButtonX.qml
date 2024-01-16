import QtQuick
import QtQuick.Controls


Item {

    id: buttonRoot

    property var text: ""

    signal buttonXClicked

    Rectangle {
        id: button
        radius: 3
        border.width: 1
        anchors.fill: parent
        border.color: borderColor
        color: Material.background

        Text {
            id: buttonText
            color: "white"
            anchors.centerIn: parent
            text: qsTr(buttonRoot.text)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter            
        }

        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            onClicked: {
                buttonXClicked()
            }
            onEntered: button.color = "steelblue"
            onExited: button.color = Material.background
        }
    }
}