import QtQuick
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
        height: 20
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
          width: 20
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
        spacing: 5
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.85
        anchors.margins: 5
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        model: ftpModel.transferModel
        currentIndex: -1
        delegate: TransferQueueDelegate{}
        highlight: Rectangle { color: "lightsteelblue"; radius: 2 }
      }
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10        
        height: parent.height * 0.15        
        anchors.top: queue.bottom
        color: "transparent"
        Text {
          color: "white"
          text: "Queued : " + queue.count
        }
      }
    }
  }
}