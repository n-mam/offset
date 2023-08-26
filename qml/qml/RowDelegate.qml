import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Rectangle {
  id: rowDelegate
  // radius: 5
  // border.width: 1
  // border.color: "#00bfff"
  color: parent.color

  readonly property real indent: 8
  readonly property real padding: 5
  readonly property real columnRowHeight: 16
  readonly property real optionsWidth: 52

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
    width: 12; height: 12
    visible: rowDelegate.hasChildren
    x: rowDelegate.padding + (3 * rowDelegate.depth * rowDelegate.indent)
    rotation: model.expanded ? 90 : 0
    anchors.top: rowDelegate.top
    MouseArea {
      hoverEnabled: true
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
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
    spacing: 2
    anchors.top: rowDelegate.top
    x: checkBox.x + checkBox.width + rowDelegate.padding + 3

    Text {
      id: label
      text: model.display[0]
      color: model.textColor
      MouseArea {
        width: rowDelegate.width
        height: rowDelegate.height
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
          if (mouse.button == Qt.LeftButton) {

          }
          else if (mouse.button == Qt.RightButton){

          }
        }
      }
    }

    Text {
      id: secondLabel
      color: model.textColor
      text: model.display[1] !== undefined ? model.display[1] : ""
    }

    Row {
      id: metadata
      spacing: rowDelegate.padding
      width: metadata1.width + metadata2.width + metadata3.width + formatRect.width + sourceRect.width + excludeRect.width
      Text {
        id: metadata1
        color: "#99F6FF"
        text: model.metaDataRole[0].trim()
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: metadata2
        color: "#99F6FF"
        text: model.metaDataRole[1].trim().length ? model.metaDataRole[1].trim() : ""
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: metadata3
        color: "#99F6FF"
        text: (model.metaDataRole[2] && model.metaDataRole[2].trim() !== "0") ? model.metaDataRole[2].trim() : ""
        anchors.verticalCenter: parent.verticalCenter
      }
      Rectangle {
        id: formatRect
        radius: 3
        border.width: 1
        border.color: "#EB5DFF"
        color: "transparent"
        width: optionsWidth
        height: rowDelegate.columnRowHeight * 0.92
        x: metadata1.width + metadata2.width + metadata3.width + rowDelegate.padding
        visible: model.selected
        Text {
          color: "white"
          height: parent.height
          text: model.formatOptions[model.formatIndex];
          anchors.verticalCenter: parent.verticalCenter
          anchors.horizontalCenter: parent.horizontalCenter
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            model.formatIndex = (model.formatIndex + 1) % model.formatOptions.length
          }
        }
      }
      Rectangle {
        id: sourceRect
        radius: 3
        border.width: 1
        border.color: (sourceText.text === "live") ? "#FF5D00" : "#00FFFC"
        color: "transparent"
        width: optionsWidth * 0.65
        height: rowDelegate.columnRowHeight * 0.92
        x: formatRect.x + formatRect.width + rowDelegate.padding
        visible: model.selected
        Text {
          id: sourceText
          color: "white"
          height: parent.height
          text: model.sourceOptions[model.sourceIndex]
          anchors.verticalCenter: parent.verticalCenter
          anchors.horizontalCenter: parent.horizontalCenter
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            model.sourceIndex = (model.sourceIndex + 1) % model.sourceOptions.length
          }
        }
      }
      Rectangle {
        id: excludeRect
        radius: 3
        border.width: 1
        border.color: "#56E71F"
        color: "transparent"
        width: optionsWidth
        height: rowDelegate.columnRowHeight * 0.92
        x: sourceRect.x + sourceRect.width + rowDelegate.padding
        visible: model.selected && (model.sourceOptions[model.sourceIndex] == "vss")
        Rectangle{
          id: excludeRectText
          width: parent.width * 0.67
          height: parent.height
          anchors.left: parent.left
          color: "transparent"
          Text {
            color: "white"
            text: "exl+"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
        Rectangle {
          id: spacer
          width: 1
          height: parent.height
          radius: 3
          border.width: 1
          border.color: "#56E71F"
          color: "transparent"
          anchors.left: excludeRectText.right
        }
        Rectangle {
          id: excludeCount
          width: excludeRect.width * 0.33
          height: parent.height
          anchors.left: spacer.right
          color: "transparent"
          Text {
            color: "white"
            text: model.excludeList.length
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
        MouseArea {
          hoverEnabled: true
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: popup.open()
        }
        ExcludeListPopup{
          id: popup
          parent: usage
          width: usage.width
          height: 275
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
      height: usage.create ? (rowDelegate.columnRowHeight * 0.88) : 0
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

  FileDialog {
    id: multiFileDialog
    fileMode: FileDialog.OpenFiles
    onAccepted: function() {
      var normalized = []
      for (var i = 0; i < files.length; i++) {
        var file = files[i].toString();
        var path = file.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
        normalized.push(decodeURIComponent(path).replace(/\//g, "\\"))
      }
      if (normalized.length) {
        model.excludeList = normalized
      }
    }
  }

  Component.onCompleted: {}
}