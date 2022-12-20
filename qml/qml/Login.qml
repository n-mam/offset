import QtQuick
import QtQuick.Controls

Rectangle {
  radius: 2
  border.width: 1
  border.color: "#5FFAFF"
  color: Material.background

  property var rowHeight: 50
  height: (rowHeight * 4) + 3

  Column {
    width: parent.width
    Row {
      spacing: 5
      anchors.margins: 5
      height: rowHeight
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: hostname
        width: parent.width * 0.81
        height: parent.height * 0.90
        placeholderText: qsTr("Host")
        horizontalAlignment: TextInput.AlignHCenter
      }
      TextField {
        id: port
        width: parent.width * 0.17
        height: parent.height * 0.90
        placeholderText: qsTr("Port")
        validator: IntValidator {bottom: 1; top: 1000}
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Row {
      spacing: 8
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 5
      height: rowHeight
      TextField {
        id: username
        width: parent.width
        height: parent.height * 0.90
        placeholderText: qsTr("User")
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Row {
      spacing: 8
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 5
      height: rowHeight
      TextField {
        id: password
        width: parent.width
        height: parent.height * 0.90        
        echoMode: TextInput.Password
        placeholderText: qsTr("Password")
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 5
      height: rowHeight
      color: Material.background
      Button {
        width: parent.width * 0.40
        height: parent.height * 0.83
        text: "Connect"
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }
}