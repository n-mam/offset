import QtQuick
import QtQuick.Controls

Rectangle {
  radius: 3
  border.width: 1
  border.color: borderColor
  color: "transparent"
  width: parent.width
  height: parent.height

  SplitView {
    id: splitViewTop
    orientation: Qt.Vertical
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: ftpFooter.top

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
      SplitView.preferredHeight: (parent.height * 0.74) - 2

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
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 2
      anchors.rightMargin: 2
      SplitView.minimumHeight: 90
      SplitView.preferredHeight: parent.height * 0.25
      color: Material.background
      // radius: 5
      // border.width: 1
      // border.color: borderColor
    
      ListView {
        id: queue
        clip: true
        spacing: 1
        anchors.fill: parent
        anchors.topMargin: 5
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        model: ftpModel.transferModel
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 100
        highlightMoveVelocity: 800
        delegate: TransferQueueDelegate{}
        highlight: Rectangle { color: "lightsteelblue"; radius: 2 }
      }
    }
  }

  FTPFooter {
    id: ftpFooter
    height: 25
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom    
    Connections {
      target: logger
      function onUpdateStatus(key, status) {
        if (key === 1) {
          ftpFooter.currentStatus = status
        }
      }
    }
  }
}