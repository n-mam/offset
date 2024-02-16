import QtQuick
import QtQuick.Controls

Item {

  signal login(var host, var port, var user, var password, var protocol)

  Column {
    spacing: 20
    width: parent.width - 25
    Row {
      spacing: 5
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: hostname
        text: "ftp.gnu.org"
        height: textFieldHeight
        width: parent.width * 0.78
        placeholderText: qsTr("Host")
        anchors.bottom: parent.bottom
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
      }
      TextField {
        id: port
        text: "21"
        height: textFieldHeight
        width: parent.width * 0.21
        placeholderText: qsTr("Port")
        anchors.bottom: parent.bottom
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        validator: IntValidator {bottom: 1; top: 1000}
      }
    }

    Row {
      spacing: 5
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
      anchors.left: parent.left
      anchors.right: parent.right
      TextField {
        id: password
        text: "welcome123"
        width: parent.width
        height: textFieldHeight
        echoMode: TextInput.Password
        anchors.bottom: parent.bottom
        placeholderText: qsTr("Password")
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
      }
    }

    Row {
        id: choices
        spacing: 8
        height: textFieldHeight
        anchors.horizontalCenter: parent.horizontalCenter
        RadioButton {
          text: qsTr("FTP")
        }
        RadioButton {
          checked: true
          text: qsTr("FTPS")
        }
    }

    ButtonGroup {
      id: optionsGroup
      buttons: choices.children
    }

    ButtonX {
      text: "Connect"
      height: textFieldHeight
      width: parent.width * 0.40
      anchors.horizontalCenter: parent.horizontalCenter
      onButtonXClicked: {
        login(hostname.text, port.text, username.text, password.text, optionsGroup.checkedButton.text)
      }
    }
  }
}