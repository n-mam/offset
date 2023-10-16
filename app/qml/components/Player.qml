import QtQuick
import QtQuick.Controls
import CustomElements 1.0

Item {

  id: playerRoot
  property var source

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
                    vr.start()
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
                    //vr.stop()
                }
            }
        }
    }
  }

}
