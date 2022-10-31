import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 2.12

TreeView {
  id: treeeView
  model: treeModel
  rowSpacing: 2
  delegate: Rectangle {
    id: treeDelegate
    radius: 5
    border.width: 1
    border.color: "grey"
    color: Material.background

    // Assigned to by TreeView:
    required property TreeView treeView
    required property bool isTreeNode
    required property bool expanded
    required property int hasChildren
    required property int depth

    implicitWidth: parent.width
    implicitHeight: 32

    width: parent.width
    height: 32

    RowDelegate {
      depth: treeDelegate.depth
      treeView: treeDelegate.treeView
      expanded: treeDelegate.expanded
      isTreeNode: treeDelegate.isTreeNode
      hasChildren: treeDelegate.hasChildren
      onUpdateItemSelection: (name, selected) => {
        treeeView.model.updateItemSelection(name, selected);
      }
    }

    TapHandler {
      onTapped: treeView.toggleExpanded(row)
    }
  }

  Component.onCompleted: {
    expandRecursively();
  }
}