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
        strokeColor: "white"
        strokeStyle: ShapePath.SolidLine
        startX: 0; startY: 0
        PathLine {x: parent.width; y: 0}
      }
    }
  }

  Text {
    text: currentStatus
    color: "white"
    width: parent.width * 0.55
    elide: Text.ElideRight
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.margins: 5
    verticalAlignment: Text.AlignVCenter
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
        target: ftpModel.transferManager
        function onTransferQueueSize(n) {
          queueCount.text = "Q:" + n
        }
      }
    }

    Text {
      id: successCount
      color: "#2EDE79"
      anchors.left: queueCount.right
      anchors.leftMargin: 10
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      Connections {
        target: ftpModel.transferManager
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
        target: ftpModel.transferManager
        function onTransferFailed(i, n) {
          failedCount.text = "F:" + n
        }
      }
    }

    Image {
      width: 20; height: 20
      source: "qrc:/queue.png"
      anchors.right: clear.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: ftpModel.transferManager.ProcessAllTransfers()
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
      }
    }

    Image {
      id: clear
      width: 20; height: 20
      source: "qrc:/delete.png"
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: ftpModel.transferManager.RemoveAllTransfers()
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
      }
    }
  }
}