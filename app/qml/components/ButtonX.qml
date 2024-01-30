import QtQuick
import QtQuick.Controls


Item {

    id: buttonRoot

    property var text: ""
    property var image: ""

    signal buttonXClicked

    Rectangle {
        id: button
        radius: 3
        anchors.fill: parent
        border.color: borderColor
        color: Material.background
        border.width: buttonRoot.text.length ? 1 : 0

        Image {
            id: buttonImage
            width: buttonRoot.width
            height: buttonRoot.height
            source: buttonRoot.image
            visible: buttonRoot.image.length
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            id: buttonText
            color: textColor
            anchors.centerIn: parent
            text: qsTr(buttonRoot.text)
            visible: buttonRoot.text.length
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter            
        }

        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onEntered: button.color = "steelblue"
            onExited: button.color = Material.background
            onClicked: {
                buttonXClicked()
            }
        }
    }
}