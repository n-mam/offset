import QtQuick
import QtQuick.Controls

Popup {

    property var inputHint: ""
    property var inputValue: ""
    property var elementName: ""
    required property var context
    property var elementIsDir: false

    signal dismissed(var userInput)

    closePolicy: Popup.NoAutoClose

    contentItem: Item {
        anchors.fill: parent
        Rectangle {
            radius: 3
            border.width: 1
            border.color: borderColor
            width: 284
            height: 164
            color: Qt.lighter(Material.background)

            Text {
                id: title
                text: context
                color: textColor
                anchors.margins: 10
                elide: Text.ElideMiddle
                anchors.top: parent.top
                width: parent.width * 0.80
                anchors.horizontalCenter: parent.horizontalCenter
            }
            TextField {
                id: userInput
                text: inputValue
                anchors.margins: 20
                width: parent.width - 20
                anchors.top: title.bottom
                placeholderText: inputHint
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                anchors.horizontalCenter: parent.horizontalCenter
                onAccepted: {}
            }
            Rectangle {
                height: 40
                anchors.margins: 10
                width: parent.width * 0.60
                anchors.top: userInput.bottom
                color: Qt.lighter(Material.background)
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    text: "OK"
                    height: parent.height
                    width: 64
                    anchors.left: parent.left
                    onClicked: dismissed(userInput.text)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Button {
                    text: "Cancel"
                    height: parent.height
                    onClicked: dismissed("")
                    width: 96
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
    onOpened: {}
    onClosed: {}
}