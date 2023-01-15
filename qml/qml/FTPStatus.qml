import QtQuick
import QtQuick.Controls

Rectangle {
  height: 25
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.bottom: parent.bottom
  anchors.leftMargin: 10
  anchors.rightMargin: 10
  color: "transparent"
  Text {
    id: queueCount
    color: "#8CDCFE"
    anchors.left: parent.left
    verticalAlignment: Text.AlignVCenter
    anchors.verticalCenter: parent.verticalCenter
    Connections {
      target: ftpModel.transferModel
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
      target: ftpModel.transferModel
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
      target: ftpModel.transferModel
      function onTransferFailed(i, n) {
        failedCount.text = "F:" + n
      }
    }    
  }
  Image {
    width: 16; height: 16
    source: "qrc:/queue.png"
    anchors.right: clear.left
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    MouseArea {
      anchors.fill: parent
      onClicked: ftpModel.transferModel.ProcessAllTransfers()
      cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
  }        
  Image {
    id: clear
    width: 16; height: 16
    source: "qrc:/delete.png"
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    MouseArea {
      anchors.fill: parent
      onClicked: ftpModel.transferModel.RemoveAllTransfers()
      cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
  }
}