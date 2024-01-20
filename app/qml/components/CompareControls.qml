import QtQuick
import QtQml.Models
import QtQuick.Controls

Item {

    Row {
        spacing: 4
        anchors.margins: 10
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        ButtonX {
            text: "-"
            width: 24
            height: 26
            onButtonXClicked: pointSize -= 1
        }
        TextField {
            width: 46
            height: 26
            color: textColor
            font.pointSize: 8
            text: pointSize.toString()
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            onAccepted: pointSize = parseInt(text, 10)
        }
        ButtonX {
            text: "+"
            width: 24
            height: 26
            onButtonXClicked: pointSize += 1
        }
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        ButtonX {
            width: 62
            height: 26
            text: "Compare"
            onButtonXClicked: compareManager.compare()
        }
    }
}