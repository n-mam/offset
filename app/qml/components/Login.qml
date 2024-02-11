import QtQuick
import QtQuick.Controls

Rectangle {
  // radius: 3
  // border.width: 1
  // border.color: "#5FFAFF"
  color: "transparent"

  property var rowHeight: 43
  height: (rowHeight * 5) + 3
  signal login(var host, var port, var user, var password, var protocol)

  Column {
    spacing: 6
    width: parent.width
    Row {
      spacing: 5
      height: rowHeight
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: hostname
        text: "ftp.gnu.org"
        height: textFieldHeight
        width: parent.width * 0.75
        placeholderText: qsTr("Host")
        anchors.bottom: parent.bottom
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
      }
      TextField {
        id: port
        text: "21"
        height: textFieldHeight
        width: parent.width * 0.23
        placeholderText: qsTr("Port")
        anchors.bottom: parent.bottom
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        validator: IntValidator {bottom: 1; top: 1000}
      }
    }

    Row {
      spacing: 5
      height: rowHeight
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: username
        text: "anonymous"
        width: parent.width
        height: textFieldHeight
        placeholderText: qsTr("User")
        anchors.bottom: parent.bottom
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Row {
      spacing: 5
      height: rowHeight
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: password
        text: "welcome123"
        width: parent.width
        height: parent.height * 0.90
        echoMode: TextInput.Password
        anchors.bottom: parent.bottom
        placeholderText: qsTr("Password")
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    ButtonGroup {
      id: optionsGroup
      buttons: choices.children
    }

    Row {
        id: choices
        spacing: 10
        height: rowHeight
        anchors.horizontalCenter: parent.horizontalCenter
        RadioButton {
          text: qsTr("FTP")
        }
        RadioButton {
          checked: true
          text: qsTr("FTPS")
        }
    }

    Rectangle {
      height: rowHeight
      anchors.margins: 7
      anchors.left: parent.left
      anchors.right: parent.right
      color: Material.background
      Button {
        text: "Connect"
        width: parent.width * 0.43
        height: parent.height * 0.90
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
          login(hostname.text, port.text, username.text, password.text, optionsGroup.checkedButton.text)
        }
      }
    }
  }
}