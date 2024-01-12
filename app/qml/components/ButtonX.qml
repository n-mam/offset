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
            anchors.fill: parent
            onClicked: {
                buttonXClicked()
            }
        }
    }
}

// Button {
//     id: control
//     padding: 0

//     contentItem: Text {
//         color: textColor
//         text: control.text
//         font: control.font
//         opacity: enabled ? 1.0 : 0.3
//         horizontalAlignment: Text.AlignHCenter
//         verticalAlignment: Text.AlignVCenter
//         elide: Text.ElideRight
//     }

//     background: Rectangle {
//         radius: 3
//         border.width: 1
//         implicitWidth: 32
//         implicitHeight: 32
//         opacity: enabled ? 1 : 0.3
//         color: Material.background
//         border.color: control.down ? "white" : borderColor
//     }
// }