import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Column {
  spacing: 5

  Rectangle {
    id: listRect
    radius: 5
    border.width: 1
    border.color: borderColor
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height * 0.75
    color: Material.background
    Rectangle {
      width: 18
      height: 18
      z: 2
      color: "transparent"
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: 5
      radius: 3
      border.width: 1
      border.color: "#FA8072"
      Text {
        text: "R"
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: { 
          diskListModel.refreshModel()
        }
      }
    }
    List {
      anchors.fill: parent
      anchors.margins: 10
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
    height: parent.height * 0.09
    color: Material.background
    radius: 5
    border.width: 1
    border.color: borderColor
    TextField {
      id: destination
      width: (parent.width * 0.75) - mainColumn.spacing
      anchors.left: parent.left
      anchors.margins: 10
      placeholderText: "Destination"
      text: folderDialog.folder
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
    id: actionsRect
    // radius: 5
    // border.width: 1
    // border.color: borderColor
    color: Material.background
    anchors.horizontalCenter: parent.horizontalCenter
    width: 75 + 75 + (3 * mainColumn.spacing)
    height: parent.height * 0.09
    Button {
      id: startButton
      width: 75
      text: "START"
      enabled: !diskListModel.transfer
      height: actionsRect.height * 0.80
      anchors.left: actionsRect.left
      anchors.margins: mainColumn.spacing
      anchors.verticalCenter: actionsRect.verticalCenter
      onClicked: {
        diskListModel.convertSelectedItemsToVirtualDisks(destination.text.length ? destination.text : ".\\")
      }
    }
    Button {
      id: cancelbutton
      width: 75
      text: "CANCEL"
      enabled: diskListModel.transfer
      height: actionsRect.height * 0.80
      anchors.left: startButton.right
      anchors.margins: mainColumn.spacing
      anchors.verticalCenter: actionsRect.verticalCenter
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