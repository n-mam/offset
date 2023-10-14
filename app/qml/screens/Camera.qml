import QtQuick
import QtQuick.Controls

Rectangle {
  id: camRoot
  radius: 3
  clip: true
  border.width: 1
  border.color: borderColor
  color: "transparent"

  Grid {
    id: camGrid
    columns: 3
    spacing: 6
    height: parent.height * 0.85
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 6
    //Player{}
  }

  Row {
    id: camControl
    spacing: 10
    anchors.top: camGrid.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height * 0.10
    TextField {
      id: cameraUrl
      width: parent.width * 0.80
      height: parent.height * 0.80
      placeholderText: qsTr("Camera URL")
      text: "rtsp://user:pass@ip"
      horizontalAlignment: TextInput.AlignHCenter
    }
    Button {
      width: 80
      height: parent.height * 0.80
      text: "ADD"
      onClicked: {
        var component = Qt.createComponent("Player.qml")
        var object = component.createObject(camGrid, {
          "source": "hello",
          "width": (camRoot.width / 3) - 10,
          "height": (camRoot.height / 2) - camControl.height
        });
      }
    }
  }

}