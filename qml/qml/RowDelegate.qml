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
  property bool isSelected: false
  property TreeView treeView

  property var typeOptions: ["vhd-d", "vhdx-d", "vhd-f"]
  property var srcOptions: ["vss", "live"]
  property var typeIndex: 0;
  property var srcIndex: 0;

  signal updateItemSelection(var name, bool selected)

  onUpdateItemSelection: (names, selected) => {
    listView.model.updateItemSelection(
      [names, typeOptions[typeIndex % 3], srcOptions[srcIndex % 2]], selected);
    //console.log([names, typeOptions[typeIndex % 3], srcOptions[srcIndex % 2]])
  }

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
      id: secondLabel
      text: model.display[1] !== undefined ? model.display[1] : ""
      color: model.textColorRole
    }

    Row {
      spacing: rowDelegate.padding
      bottomPadding: 2
      Text {
        id: thirdLabel
        text: (model.metaDataRole[0] + " " + model.metaDataRole[1] + " " +  model.metaDataRole[2]).replace(/ +(?= )/g,'').trim()
        color: "#5EECD9"
      }
      Rectangle {
        id: typeRect
        radius: 3
        border.width: 1
        border.color: "#EB5DFF"
        color: "transparent"
        width: 52
        height: usage.height
        x: usage.width + rowDelegate.padding
        visible: rowDelegate.isSelected
        anchors.verticalCenter: usage.verticalCenter
        Text {
          color: "white"
          text: rowDelegate.typeOptions[rowDelegate.typeIndex % 3]
          anchors.verticalCenter: typeRect.verticalCenter
          anchors.horizontalCenter: typeRect.horizontalCenter
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: { 
            rowDelegate.typeIndex++
            rowDelegate.updateItemSelection(model.display, rowDelegate.isSelected)
          }
        }
      }
      Rectangle {
        id: srcRect
        radius: 3
        border.width: 1
        border.color: (rowDelegate.srcIndex % 2) ? "#FF6969" : "#00BFFF"
        color: "transparent"
        width: 52
        height: usage.height
        x: typeRect.x + typeRect.width + rowDelegate.padding
        visible: rowDelegate.isSelected
        anchors.verticalCenter: usage.verticalCenter
        Text {
          color: "white"
          text: rowDelegate.srcOptions[rowDelegate.srcIndex % 2]
          anchors.verticalCenter: srcRect.verticalCenter
          anchors.horizontalCenter: srcRect.horizontalCenter
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: { 
            rowDelegate.srcIndex++
            rowDelegate.updateItemSelection(model.display, rowDelegate.isSelected)
          }
        }
      }
    }

    Element {
      id: usage
      type: "usage"
      create: rowDelegate.selectable && model.sizeRole > 0
      used: model.sizeRole - model.freeRole
      free: model.freeRole
      visible: usage.create
      width: (secondLabel.width ? secondLabel.width : label.width)
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