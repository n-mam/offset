import QtQuick
import QtQuick.Shapes
import QtQuick.Controls

Rectangle {
  radius: 5
  border.width: 1
  border.color: borderColor
  color: Material.background
  clip: true

  SplitView {
    id: splitViewTop
    orientation: Qt.Vertical
    anchors.fill: parent

    handle: Rectangle {
      id: handleDelegate
      implicitWidth: 1
      implicitHeight: 1
      containmentMask: Item {
        x: (handleDelegate.width - width) / 2
        width: splitViewTop.width
        height: 15
      }
    }

    SplitView {
      id: splitView
      implicitHeight: parent.height * 0.70

      handle: Rectangle {
        id: handleDelegate
        implicitWidth: 1
        implicitHeight: 1
        containmentMask: Item {
          x: (handleDelegate.width - width) / 2
          width: 15
          height: splitView.height
        }
      }

      LocalListView{}
      RemoteListView{}
    }

    Rectangle {
      id: transferQueue
      width: parent.width
      height: parent.height * 0.30
      color: "transparent"
      // radius: 5
      // border.width: 1
      // border.color: borderColor
    
      ListView {
        id: queue
        clip: true
        spacing: 3
        height: parent.height - spacer.height - queueStatus.height
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 5
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        model: ftpModel.transferModel
        currentIndex: -1
        delegate: TransferQueueDelegate{}
        highlight: Rectangle { color: "lightsteelblue"; radius: 2 }
      }

      Rectangle {
        id: spacer
        color: "transparent"
        width: parent.width
        height: 1
        anchors.top: queue.bottom
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

      Rectangle {
        id: queueStatus
        height: 25
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: "transparent"
        Text {
          color: "white"
          text: "Queue : " + queue.count
          verticalAlignment: Text.AlignVCenter
          anchors.verticalCenter: parent.verticalCenter          
        }
      }
    }
  }
}