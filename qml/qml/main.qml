import QtQuick
import QtQuick.Controls
import Qt.labs.platform

ApplicationWindow {
  width: 575
  height: 465
  visible: true
  title: qsTr("FXC")

  Column {
    id: mainColumn
    spacing: 5
    padding: 5
    width: parent.width - padding
    height: parent.height - padding

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.leftMargin: 10
      height: parent.height * 0.75
      color: Material.background
      radius: 5
      border.width: 1
      border.color: "#a7c497"
      List {
        anchors.fill: parent
        anchors.margins: 2
        model: diskListModel
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.leftMargin: 10
      height: parent.height * 0.10
      color: Material.background
      radius: 5
      border.width: 1
      border.color: "#a7c497"
      TextField {
        id: destination
        width: (parent.width * 0.70) - (2 * mainColumn.padding)
        anchors.left: parent.left
        anchors.margins: 10
        placeholderText: qsTr("Destination")
        text: folderDialog.currentFolder
      }
      Button {
        text: "Select"
        width: parent.width * 0.20
        height: parent.height * 0.80
        anchors.right: parent.right
        anchors.margins: 10
        onClicked: folderDialog.open()
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Rectangle {
      id: actions
      // radius: 5
      // border.width: 1
      // border.color: "#a7c497"
      color: Material.background
      anchors.horizontalCenter: parent.horizontalCenter
      width: 75 + 75 + (3 * mainColumn.padding)
      height: parent.height * 0.10
      Button {
        id: startButton
        width: 75
        text: "START"
        height: actions.height * 0.80
        anchors.left: actions.left
        anchors.margins: mainColumn.padding
        anchors.verticalCenter: actions.verticalCenter
        onClicked: {
          var selected = diskListModel.getSelectedItems()
          console.log(selected)
        }
      }
      Button {
        id: cancelbutton
        width: 75
        text: "CANCEL"
        height: actions.height * 0.80
        anchors.left: startButton.right
        anchors.margins: mainColumn.padding
        anchors.verticalCenter: actions.verticalCenter
      }
    }
  }

  FolderDialog {
    id: folderDialog
    onAccepted: {
      var path = folderDialog.folder.toString();
      path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
      destination.text = decodeURIComponent(path).replace(/\//g, "\\")
    }
  }
}
