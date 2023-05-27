import QtQuick
import QtQuick.Controls
import CustomElements 1.0

Item {

  id: playerRoot
  required property var source

  Rectangle {
    border.width: 1
    border.color: "white"
    color: "transparent"
    anchors.fill: parent

    VideoPlayer {
      id: vp
      width: parent.width
      height: parent.height
      source: playerRoot.source
    }
  }

}
