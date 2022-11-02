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
    color: Material.background
    width: listView.width
    implicitHeight: rd.height //75

    RowDelegate {
      id: rd
      depth: model.depthRole
      selectable: model.selectableRole
      isTreeNode: model.hasChildrenRole
      hasChildren: model.hasChildrenRole
      onUpdateItemSelection: (names, selected) => {
        listView.model.updateItemSelection(names, selected);
      }
    }
    TapHandler {
      onTapped: console.log("list row tapped")
    }
  }
}