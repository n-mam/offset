import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Rectangle {
  // radius: 5
  // border.width: 1
  // border.color: borderColor
  color: Material.background

  Rectangle {
    id: listRect
    radius: 5
    border.width: 1
    border.color: borderColor
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height * 0.75
    color: "transparent"
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

        }
      }
    }
  }

  Rectangle {
    id: destinationRect
    anchors.top: listRect.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: 5
    height: parent.height * 0.10
    color: "transparent"
    radius: 5
    border.width: 1
    border.color: borderColor
    TextField {
      id: destination
      width: (parent.width * 0.75) - appSpacing
      anchors.left: parent.left
      anchors.margins: 10
      placeholderText: "Destination"
      text: folderDialog.folder
      anchors.verticalCenter: parent.verticalCenter
      Component.onCompleted: font.pointSize = font.pointSize - 1.5
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
    anchors.top: destinationRect.bottom
    color: "transparent"
    anchors.horizontalCenter: parent.horizontalCenter
    width: 75 + 75 + (3 * appSpacing)
    height: parent.height * 0.10
    Button {
      id: startButton
      width: 75
      text: "START"
      enabled: (diskListModel.transfer === 0)
      height: parent.height * 0.80
      anchors.left: parent.left
      anchors.margins: appSpacing
      anchors.verticalCenter: parent.verticalCenter
      onClicked: {
        diskListModel.convertSelectedItemsToVirtualDisks(destination.text)
      }
    }
    Button {
      id: cancelbutton
      width: 75
      text: "CANCEL"
      enabled: (diskListModel.transfer !== 0)
      height: parent.height * 0.80
      anchors.left: startButton.right
      anchors.margins: appSpacing
      anchors.verticalCenter: parent.verticalCenter
      onClicked: {
        diskListModel.stop = true;
      }
    }
  }

  Text {
    id: statusText
    text: "Ready"
    color: "white"
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    Component.onCompleted: statusText.font.pointSize = statusText.font.pointSize - 1.0
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