import QtQuick
import QtQuick.Controls

Rectangle {
  radius: 2
  border.width: 1
  border.color: "#5FFAFF"
  color: Material.background

  property var rowHeight: 45
  height: (rowHeight * 4) + 3
  signal login(var host, var port, var user, var password)

  Column {
    width: parent.width
    Row {
      spacing: 5
      height: rowHeight
      anchors.margins: 5
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: hostname
        width: parent.width * 0.81
        height: parent.height * 0.90
        placeholderText: qsTr("Host")
        text: "127.0.0.1"
        horizontalAlignment: TextInput.AlignHCenter
      }
      TextField {
        id: port
        width: parent.width * 0.17
        height: parent.height * 0.90
        placeholderText: qsTr("Port")
        validator: IntValidator {bottom: 1; top: 1000}
        text: "21"
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Row {
      spacing: 5
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 5
      height: rowHeight
      TextField {
        id: username
        width: parent.width
        height: parent.height * 0.90
        placeholderText: qsTr("User")
        text: "nmam"
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Row {
      spacing: 5
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
        text: "welcome123"
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Rectangle {
      height: rowHeight
      anchors.margins: 5
      anchors.left: parent.left
      anchors.right: parent.right
      color: Material.background
      Button {
        width: parent.width * 0.38
        height: parent.height * 0.85
        text: "Connect"
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
          login(hostname.text, port.text, username.text, password.text)
        }
      }
    }
  }
}