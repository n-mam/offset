import QtQuick
import QtQuick.Shapes
import QtQuick.Controls

Item {

  property var currentStatus: "Ready"

  Rectangle {
    id: spacer
    color: "transparent"
    width: parent.width
    height: 1
    anchors.top: parent.top
    Shape {
      anchors.fill: parent
      anchors.centerIn: parent
      ShapePath {
        strokeWidth: 1
        strokeColor: borderColor
        strokeStyle: ShapePath.SolidLine
        startX: 1; startY: 0
        PathLine {x: parent.width; y: 0}
      }
    }
  }

  Text {
    color: textColor
    text: currentStatus
    height: parent.height - 1
    anchors.leftMargin: 5
    elide: Text.ElideRight
    anchors.left: parent.left
    width: parent.width * 0.55
    anchors.bottom: parent.bottom
    verticalAlignment: Text.AlignVCenter
    anchors.verticalCenter: parent.verticalCenter
  }

}