import QtQuick
import QtQuick.Controls

Popup {

  required property var context;

  signal dismissed(var userInput)

  contentItem: Item {
    anchors.fill: parent
    Rectangle {
      radius: 3
      border.width: 1
      border.color: "white"
      color: Qt.darker(Material.background)
      width: 240
      height: 150

      Text {
        id: title
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
        placeholderText: qsTr("Remote Directory")
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        onAccepted: {

        }
        Component.onCompleted: font.pointSize = font.pointSize - 1.5
      }
      Rectangle {
        width: parent.width * 0.65
        height: 40
        anchors.top: userInput.bottom
        anchors.margins: 10
        anchors.horizontalCenter: parent.horizontalCenter
        color: Qt.darker(Material.background)
        Button {
          id: okButton
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