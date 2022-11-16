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
  readonly property real columnRowHeight: 16

  anchors.fill: parent

  property int depth
  property int hasChildren

  signal selectionChanged(var checked)
  signal toggleTreeNode(var index, var expanded)
  signal toggleChildSelection(var index, var selected)

  onSelectionChanged: (checked) => {
    model.selected = checked;
  }

  height: Math.max(arrow.height, checkBox.height, details.height) + 10

  Image {
    id: arrow
    source: "qrc:/arrow.png"
    width: 8; height: 12
    visible: rowDelegate.hasChildren
    x: rowDelegate.padding + (3 * rowDelegate.depth * rowDelegate.indent)
    rotation: model.expanded ? 90 : 0
    anchors.top: rowDelegate.top
    MouseArea {
      hoverEnabled: true
      anchors.fill: parent
      cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: {
        model.expanded = !model.expanded
        toggleTreeNode(index, model.expanded)
      }
    }
  }

  Element {
    id: checkBox
    type: "checkBox"
    create: model.enabled
    checked: model.selected
    x: arrow.x + arrow.width + rowDelegate.padding + 3
    anchors.top: rowDelegate.top
  }

  Column {
    id: details
    spacing: 1
    anchors.top: rowDelegate.top
    x: checkBox.x + checkBox.width + rowDelegate.padding + 3

    Text {
      id: label
      font.bold: true
      text: model.display[0]
      color: model.textColor
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
      color: model.textColor
    }

    Row {
      id: metadata
      spacing: rowDelegate.padding
      bottomPadding: usage.height ? 2 : 0
      width: metadata1.width + metadata2.width + metadata3.width + formatRect.width + sourceRect.width
      Text {
        id: metadata1
        text: model.metaDataRole[0].trim()
        color: "#00ECD9"
      }
      Text {
        id: metadata2
        text: model.metaDataRole[1].trim().length ? model.metaDataRole[1].trim() : ""
        color: "#00ECD9"
      }
      Text {
        id: metadata3
        text: (model.metaDataRole[2] && model.metaDataRole[2].trim() !== "0") ? model.metaDataRole[2].trim() : ""
        color: "#00ECD9"
      }
      Rectangle {
        id: formatRect
        radius: 3
        border.width: 1
        border.color: "#EB5DFF"
        color: "transparent"
        width: 52
        height: rowDelegate.columnRowHeight
        x: usage.width + rowDelegate.padding
        visible: model.selected
        Text {
          color: "white"
          text: model.formatOptions[model.formatIndex];
          anchors.verticalCenter: formatRect.verticalCenter
          anchors.horizontalCenter: formatRect.horizontalCenter
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            model.formatIndex = (model.formatIndex + 1) % model.formatOptions.length
          }
        }
      }
      Rectangle {
        id: sourceRect
        radius: 3
        border.width: 1
        border.color: (sourceText.text === "live") ? "#FF6969" : "#00BFFF"
        color: "transparent"
        width: 52
        height: rowDelegate.columnRowHeight
        x: formatRect.x + formatRect.width + rowDelegate.padding
        visible: model.selected
        Text {
          id: sourceText
          color: "white"
          text: model.sourceOptions[model.sourceIndex]
          anchors.verticalCenter: sourceRect.verticalCenter
          anchors.horizontalCenter: sourceRect.horizontalCenter
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: {
            model.sourceIndex = (model.sourceIndex + 1) % model.sourceOptions.length
          }
        }
      }
    }

    Element {
      id: usage
      type: "usage"
      create: model.sizeRole > 0
      used: model.sizeRole - model.freeRole
      free: model.freeRole
      visible: usage.create
      width: Math.max(label.width, secondLabel.width, metadata.width)
      height: usage.create ? rowDelegate.columnRowHeight : 0
    }

    Element {
      id: progress
      type: "progress"
      create: model.sizeRole > 0
      visible: false
      value: 0
      width: (secondLabel.width ? secondLabel.width : label.width)
      height: progress.create ? 3 : 0
      Connections {
        target: diskListModel
        function onProgress(device, percent) {
          var guid = model.display[1] ? model.display[1] : model.display[0]
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