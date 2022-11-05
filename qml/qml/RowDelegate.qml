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

  height: arrow.height + checkBox.height + details.height + 12

  Image {
    id: arrow
    source: "qrc:/arrow.png"
    width: 12; height: 12
    visible: rowDelegate.isTreeNode && rowDelegate.hasChildren
    x: rowDelegate.padding + (3 * rowDelegate.depth * rowDelegate.indent)
    rotation: rowDelegate.expanded ? 90 : 0
    anchors.top: rowDelegate.top
    anchors.margins: 5

  }

  Element {
    id: checkBox
    type: "checkBox"
    create: rowDelegate.selectable
    x: arrow.x + arrow.width + rowDelegate.padding
    anchors.top: rowDelegate.top
    anchors.margins: 5
  }

  Column {
    id: details
    spacing: 1
    anchors.top: rowDelegate.top
    anchors.margins: 3
    x: checkBox.x + checkBox.width + (2 * rowDelegate.padding)

    Text {
      id: label
      font.bold: true
      text: model.display[0]
      color: model.textColorRole
      MouseArea {
        width: rowDelegate.width
        height: rowDelegate.height
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
          if (mouse.button == Qt.LeftButton)
          {
              console.log("Left")
          }
          else if (mouse.button == Qt.RightButton)
          {
              console.log(model.display)
          }
        }
      }
    }

    Text {
      id: seconLabel
      text: model.display[1] !== undefined ? model.display[1] : ""
      color: "#FF4EBC7C"
    }

    Element {
      id: usage
      type: "usage"
      create: rowDelegate.selectable && model.sizeRole > 0
      used: model.sizeRole - model.freeRole
      free: model.freeRole
      visible: usage.create
      width: 205
      height: usage.create ? 16 : 0
    }

    Element {
      id: progress
      type: "progress"
      create: rowDelegate.selectable && (model.sizeRole > 0)
      visible: false
      value: 0
      width: usage.width
      height: progress.create ? 2 : 0
      Connections {
        target: diskListModel
        function onProgress(device, percent) {
          var guid = (model.display[1] !== undefined) ? model.display[1] : model.display[0]
          if (guid.includes(device)) {
            progress.visible = true
            progress.value = percent
          }
        }
      }
    }
  }

  Component.onCompleted: {
  }
}