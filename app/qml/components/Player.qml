import QtQuick
import QtQuick.Controls
import CustomElements 1.0
import "qrc:/screens"

Item {

  property var source

  id: playerRoot

  width: mainWindow.width - (mainWindow.width * 0.72)
  height: mainWindow.height - (mainWindow.height * 0.72)

  signal cameraSettingsClickedSignal(var vr)

  Rectangle {
    border.width: 1
    border.color: "white"
    color: "transparent"
    anchors.fill: parent

    VideoRenderer {
        id: vr
        width: parent.width
        height: parent.height
        source: playerRoot.source
    }

    Row {
        spacing: 2
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        Image {
            width: 32
            height: 32
            source: "qrc:/play.png"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    vr.start(["face"])
                }
            }
        }

        Image {
            width: 32
            height: 32
            source: "qrc:/pause.png"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    vr.stop()
                }
            }
        }

        Image {
            width: 32
            height: 32
            source: "qrc:/settings.png"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    onClicked: cameraSettingsClickedSignal(vr)
                }
            }
        }
    }
  }

}
