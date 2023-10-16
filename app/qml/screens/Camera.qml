import QtQuick
import QtQuick.Controls
import "qrc:/components"

StackScreen {

  id: camRoot
  //radius: 3
  //clip: true
  //border.width: 1
  //border.color: borderColor
  //color: "transparent"

  Flickable {
      id: flickableGrid
      clip: true
      height: parent.height * 0.88
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 6
      contentHeight: camGrid.height
      contentWidth: camGrid.width

      Grid {
        id: camGrid
        columns: 4
        spacing: 6
        //Player{}
      }
  }

  Row {
    id: camControl
    spacing: 10
    anchors.top: flickableGrid.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height * 0.10
    TextField {
      id: cameraUrl
      width: parent.width * 0.80
      height: parent.height * 0.80
      placeholderText: qsTr("Camera")
      horizontalAlignment: TextInput.AlignHCenter
    }
    Button {
      width: 80
      height: parent.height * 0.80
      text: "ADD"
      onClicked: {
        if (cameraUrl.text) {
          var component = Qt.createComponent("qrc:/components/Player.qml")
          if (component.status == Component.Ready)
              finishCreation(component);
          else
              component.statusChanged.connect(finishCreation);
        }
      }
    }
  }

  function finishCreation(component) {
    var object = component.createObject(camGrid, {
      "source": cameraUrl.text,
      "width": 1280 - (1280 * 0.65),
      "height": 720 - (720 * 0.65)
    });
    cameraUrl.text = ""
  }
}