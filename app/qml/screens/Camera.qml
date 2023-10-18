import QtQuick
import QtQuick.Controls
import "qrc:/components"

StackScreen {

  id: camScreenRoot
  baseItem: baseId
  //radius: 3
  //clip: true
  //border.width: 1
  //border.color: borderColor
  //color: "transparent"

  Item {
    id: baseId
    Flickable {
        id: flickableGrid
        clip: true
        width: parent.width
        height: parent.height * 0.88
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
  }

  function finishCreation(component) {
    var object = component.createObject(camGrid, {
      "source": cameraUrl.text
    });
    cameraUrl.text = ""
    object.cameraSettingsClickedSignal.connect(cameraSettingsClicked)
  }

  function cameraSettingsClicked(vr) {
    camScreenRoot.pushComponent("qrc:/screens/CameraSettings.qml")
  }

}