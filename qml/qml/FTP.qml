import QtQuick
import QtQuick.Controls

Item {
  Column {
    spacing: 5
    anchors.fill: parent
    Rectangle {
      id: splitViewRect
      radius: 5
      border.width: 1
      border.color: borderColor
      anchors.left: parent.left
      anchors.right: parent.right
      height: parent.height * 0.75
      color: Material.background

      SplitView {
        id: splitView
        anchors.fill: parent

        handle: Rectangle {
          id: handleDelegate
          implicitWidth: 1
          implicitHeight: 1
          color: SplitHandle.pressed ? 
            "#CCD1D1" : (SplitHandle.hovered ? Qt.lighter("#CCD1D1", 1.1) : "#CCD1D1")
          containmentMask: Item {
            x: (handleDelegate.width - width) / 2
            width: 20
            height: splitView.height
          }
        }

        LocalListView{}
        RemoteListView{}
      }
    }

    Rectangle {
      id: transferQueue
      radius: 5
      border.width: 1
      border.color: borderColor
      anchors.left: parent.left
      anchors.right: parent.right
      height: parent.height * 0.18
      color: Material.background

      ListView {
        clip: true
        anchors.fill: parent
        model: ftpModel.transferModel
        delegate: Text {
          text: local + " : " + remote + " : " + "direction" + " : " + type
          color: "white"
        }
      }
    }
  }
}
