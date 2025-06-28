import QtQuick
import QtQuick.Shapes
import QtQuick.Controls
import "qrc:/components"

Item {

  property var currentStatus: "Ready"

  Rectangle {
    id: spacer
    height: 1
    width: parent.width
    color: "transparent"
    anchors.bottom: parent.top
    Shape {
      anchors.fill: parent
      anchors.centerIn: parent
      ShapePath {
        strokeWidth: 1
        startX: 1; startY: 0
        strokeColor: borderColor
        strokeStyle: ShapePath.SolidLine
        PathLine {x: parent.width; y: 0}
      }
    }
  }

  Text {
    color: textColor
    text: currentStatus
    height: parent.height
    anchors.leftMargin: 5
    elide: Text.ElideRight
    anchors.left: parent.left
    width: parent.width * 0.55
    anchors.bottom: parent.bottom
    verticalAlignment: Text.AlignVCenter
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    id: queueStats
    color: "transparent"
    height: parent.height
    width: parent.width * 0.45
    anchors.right: parent.right

    Text {
      id: queueCount
      color: "#8CDCFE"
      anchors.leftMargin: 5
      anchors.left: parent.left
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      Connections {
        target: transferManager
        function onTransferQueueSize(n) {
          queueCount.text = "Q: " + n
        }
      }
    }

    Text {
      id: activeCount
      color: "#2EDE79"
      anchors.leftMargin: 10
      anchors.left: queueCount.right
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
      anchors.leftMargin: 10
      anchors.left: activeCount.right
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
      anchors.leftMargin: 10
      anchors.left: successCount.right
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
      anchors.rightMargin: 3
      source: "qrc:/queue.png"
      anchors.right: stop.left
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: transferManager.ProcessAllTransfers()
        onContainsMouseChanged: queue.scale = 1 + (containsMouse ? 0.4 : 0)
      }
    }

    Image {
      id: stop
      width: 24; height: 24
      anchors.rightMargin: 3
      source: "qrc:/stop.png"
      anchors.right: clear.left
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: transferManager.StopAllTransfers()
        onContainsMouseChanged: stop.scale = 1 + (containsMouse ? 0.4 : 0)
      }
    }

    Image {
      id: clear
      width: 24; height: 24
      anchors.rightMargin: 5
      source: "qrc:/delete.png"
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: clear.scale = 1 + (containsMouse ? 0.4 : 0)
        onClicked: () => {
          transferManager.RemoveAllTransfers()
          successCount.text = failedCount.text = ""
        }
      }
    }
  }
}