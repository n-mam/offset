import QtQuick
import QtQuick.Controls
import "qrc:/delegates"

ListView {
  id: listView
  clip: true
  spacing: appSpacing
  currentIndex: -1
  interactive: false
  delegate: Rectangle {
    id: listDelegate
    // radius: 3
    // border.width: 1
    // border.color: "grey"
    width: listView.width
    visible: model.visible
    enabled: model.visible
    implicitHeight: rd.height
    color: Material.background

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