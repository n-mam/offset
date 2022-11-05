import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Column {
  spacing: 5

  Rectangle {
    id: listRect
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 10
    height: parent.height * 0.75
    color: Material.background
    radius: 5
    border.width: 1
    border.color: "#a7c497"
    List {
      anchors.fill: parent
      anchors.margins: 2
      model: diskListModel
      Connections {
        target: diskListModel
        function onTransferChanged(transfer) {
          console.log(transfer)
        }
      }
    }
  }

  Rectangle {
    id: destinationRect
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.leftMargin: 10
    height: parent.height * 0.09
    color: Material.background
    radius: 5
    border.width: 1
    border.color: "#a7c497"
    TextField {
      id: destination
      width: (parent.width * 0.75) - mainColumn.spacing
      anchors.left: parent.left
      anchors.margins: 10
      placeholderText: "Destination"
      text: folderDialog.currentFolder
      anchors.verticalCenter: parent.verticalCenter
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
    radius: 5
    border.width: 1
    border.color: "#a7c497"
    color: Material.background
    anchors.horizontalCenter: parent.horizontalCenter
    width: 75 + 75 + (3 * mainColumn.spacing)
    height: parent.height * 0.09
    Button {
      id: startButton
      width: 75
      text: "START"
      enabled: !diskListModel.transfer
      height: actions.height * 0.80
      anchors.left: actions.left
      anchors.margins: mainColumn.spacing
      anchors.verticalCenter: actions.verticalCenter
      onClicked: {
        diskListModel.ConvertSelectedItemsToVirtualDisks(destination.text.length ? destination.text : ".\\")
      }
    }
    Button {
      id: cancelbutton
      width: 75
      text: "CANCEL"
      enabled: diskListModel.transfer
      height: actions.height * 0.80
      anchors.left: startButton.right
      anchors.margins: mainColumn.spacing
      anchors.verticalCenter: actions.verticalCenter
      onClicked: {
        diskListModel.stop = true;
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