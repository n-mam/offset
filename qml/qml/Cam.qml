import QtQuick
import QtQuick.Controls

Rectangle {
  radius: 3
  border.width: 1
  border.color: borderColor
  color: "transparent"
  width: parent.width
  height: parent.height

  Grid {
    id: camGrid
    columns: 4
    spacing: 10
    height: parent.height * 0.90
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right    
    anchors.margins: 4
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
          "width": 100,
          "height": 100
        });
      }
    }      
  }

}