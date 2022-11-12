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
    visible: model.visible
    enabled: model.visible

    property var originalHeight;

    RowDelegate {
      id: rd
      depth: model.depth
      hasChildren: model.hasChildren
      onToggleTreeNode: (index, expanded) => {
        listView.model.ToggleTreeExpandedAtIndex(index, expanded)
      }
      onToggleChildSelection: (index, selected) => {
        listView.model.ToogleChildSelectionAtindex(index, selected)
      }
    }
    TapHandler {
      //onTapped: console.log("list row tapped")
    }
    Connections {
      target: diskListModel
      function onDataChanged() {
        listDelegate.height = model.visible ? listDelegate.originalHeight : 0
      }
    }
    Component.onCompleted: {
      originalHeight = listDelegate.height
    }
  }
}