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
      implicitHeight: parent.height * 0.75

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
      height: parent.height * 0.25
      color: "transparent"
      // radius: 5
      // border.width: 1
      // border.color: borderColor
    
      ListView {
        clip: true
        spacing: 5
        anchors.fill: parent
        anchors.margins: 5
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        model: ftpModel.transferModel
        currentIndex: -1
        delegate: TransferQueueDelegate{}
        highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
      }
    }
  }
}