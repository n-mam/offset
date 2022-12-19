import QtQuick
import QtQuick.Controls

Item {
  SplitView {
    id: splitView
    anchors.fill: parent
    anchors.margins: 2

    handle: Rectangle {
      id: handleDelegate
      implicitWidth: 2
      implicitHeight: 2
      anchors.margins: 5
      color: SplitHandle.pressed ? 
        "#CCD1D1" : (SplitHandle.hovered ? Qt.lighter("#CCD1D1", 1.1) : "#CCD1D1")
      containmentMask: Item {
        x: (handleDelegate.width - width) / 2
        width: 64
        height: splitView.height
      }
    }

    LocalListView{}

    RemoteListView{}
  }
}
