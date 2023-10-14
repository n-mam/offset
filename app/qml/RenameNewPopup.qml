import QtQuick
import QtQuick.Controls

Popup {

  required property var context
  property var elementName: ""
  property var elementIsDir: false
  property var inputHint: ""
  property var inputValue: ""

  signal dismissed(var userInput)

  contentItem: Item {
    anchors.fill: parent
    Rectangle {
      radius: 3
      border.width: 1
      border.color: "white"
      color: Qt.darker(Material.background)
      width: 284
      height: 164

      Text {
        id: title
        width: parent.width * 0.80
        elide: Text.ElideMiddle
        color: "white"
        text: context
        anchors.top: parent.top
        anchors.margins: 10
        anchors.horizontalCenter: parent.horizontalCenter
      }
      TextField {
        id: userInput
        width: parent.width - 20
        anchors.top: title.bottom
        anchors.margins: 20
        text: inputValue
        placeholderText: inputHint
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        onAccepted: {

        }
      }
      Rectangle {
        width: parent.width * 0.75
        height: 40
        anchors.top: userInput.bottom
        anchors.margins: 10
        anchors.horizontalCenter: parent.horizontalCenter
        color: Qt.darker(Material.background)
        Button {
          width: parent.width * 0.4
          height: parent.height
          text: "OK"
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          onClicked: dismissed(userInput.text)
        }
        Button {
          text: "Cancel"
          width: parent.width * 0.4
          height: parent.height
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          onClicked: dismissed("")
        }
      }
    }
  }
  onOpened: {
  }
  onClosed: {
  }
}