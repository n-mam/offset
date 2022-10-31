import QtQuick
import QtQuick.Controls

Rectangle {
  id: rowDelegate
  // radius: 5
  // border.width: 1
  // border.color: "#00bfff"

  color: parent.color

  readonly property real indent: 8
  readonly property real padding: 5

  anchors.fill: parent
  anchors.margins: 2

  // TreeView
  property int depth
  property bool expanded
  property bool isTreeNode
  property int hasChildren
  property bool selectable
  property TreeView treeView

  signal updateItemSelection(var name, bool selected)

  Image {
    id: arrow
    source: "qrc:/arrow.png"
    width: 12; height: 12
    visible: rowDelegate.isTreeNode && rowDelegate.hasChildren
    x: rowDelegate.padding + (rowDelegate.depth * 3 * rowDelegate.indent)
    anchors.verticalCenter: rowDelegate.verticalCenter
    rotation: rowDelegate.expanded ? 90 : 0
  }

  Element {
    id: checkBox
    type: "checkBox"
    create: rowDelegate.selectable
    anchors.verticalCenter: rowDelegate.verticalCenter
    x: arrow.x + arrow.width + rowDelegate.padding
  }

  Text {
    id: label
    text: model.display
    color: model.textColorRole
    anchors.verticalCenter: rowDelegate.verticalCenter
    x: checkBox.x + checkBox.width + rowDelegate.padding
  }

  Column {
    spacing: 2
    anchors.verticalCenter: rowDelegate.verticalCenter
    Element {
      id: usage
      type: "usage"
      create: rowDelegate.selectable
      visible: model.sizeRole > 0
      x: label.x + label.width + (2 * rowDelegate.padding)
      width: 200
      height: rowDelegate.height - (rowDelegate.height * 0.52)
    }

    ProgressBar {
      visible: model.sizeRole > 0
      x: label.x + label.width + (2 * rowDelegate.padding)
      from: 0
      to: 100
      value: model.sizeRole ? (100 * ((model.sizeRole - model.freeRole) / model.sizeRole)) : 0 
      width: usage.width
    }
  }

  Component.onCompleted: {
  }
}