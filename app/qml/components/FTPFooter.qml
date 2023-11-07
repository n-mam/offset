import QtQuick
import QtQuick.Shapes
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "qrc:/components"

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
    width: parent.width * 0.55
    height: parent.height
    elide: Text.ElideRight
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.leftMargin: 5
    verticalAlignment: Text.AlignVCenter
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    id: queueStats
    width: parent.width * 0.45
    height: parent.height
    anchors.right: parent.right
    color: "transparent"

    Text {
      id: queueCount
      color: "#8CDCFE"
      anchors.left: parent.left
      anchors.leftMargin: 5
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      Connections {
        target: transferManager
        function onTransferQueueSize(n) {
          queueCount.text = "Q:" + n
        }
      }
    }

    Text {
      id: activeCount
      color: "#2EDE79"
      anchors.left: queueCount.right
      anchors.leftMargin: 10
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      Connections {
        target: transferManager
        function onActiveTransfers(n) {
          activeCount.text = "A:" + n
        }
      }
    }

    Text {
      id: successCount
      color: "#2EDE79"
      anchors.left: activeCount.right
      anchors.leftMargin: 10
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      Connections {
        target: transferManager
        function onTransferSuccessful(i, n) {
          successCount.text = "T:" + n
        }
      }
    }

    Text {
      id: failedCount
      color: "#EF5129"
      anchors.left: successCount.right
      anchors.leftMargin: 10
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      Connections {
        target: transferManager
        function onTransferFailed(i, n) {
          failedCount.text = "F:" + n
        }
      }
    }

    Image {
      id: queue
      width: 24; height: 24
      source: "qrc:/queue.png"
      anchors.right: stop.left
      anchors.rightMargin: 3
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: transferManager.ProcessAllTransfers()
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: queue.scale = 1 + (containsMouse ? 0.4 : 0)
      }
    }
    ColorOverlay {
      anchors.fill: queue
      source: queue
      color: "#69BAE8"
    }

    Image {
      id: stop
      width: 24; height: 24
      source: "qrc:/stop.png"
      anchors.right: clear.left
      anchors.rightMargin: 3
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: transferManager.StopAllTransfers()
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: stop.scale = 1 + (containsMouse ? 0.4 : 0)
      }
    }
    ColorOverlay {
      anchors.fill: stop
      source: stop
      color: "#FF7471"
    }

    Image {
      id: clear
      width: 24; height: 24
      source: "qrc:/delete.png"
      anchors.right: parent.right
      anchors.rightMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: () => {
          transferManager.RemoveAllTransfers()
          successCount.text = failedCount.text = ""
        }
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: clear.scale = 1 + (containsMouse ? 0.4 : 0)
      }
    }
  }
}