import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 2.12

ListView {
  id: listView
  clip: true
  currentIndex: -1
  delegate: Rectangle {
    id: listDelegate
    // radius: 5
    // border.width: 1
    // border.color: "grey"
    width: listView.width
    implicitHeight: rd.height
    color: Material.background
    RowDelegate {
      id: rd
      depth: model.depthRole
      selectable: model.selectableRole
      hasChildren: model.hasChildrenRole
    }
    TapHandler {
      onTapped: console.log("list row tapped")
    }
  }
}