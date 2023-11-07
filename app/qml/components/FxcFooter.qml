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
    anchors.bottom: parent.top
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
    text: currentStatus
    color: textColor
    width: parent.width * 0.50
    elide: Text.ElideRight
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.margins: 5
    verticalAlignment: Text.AlignVCenter
  }

}