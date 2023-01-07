import QtQuick
import QtQuick.Controls
import Qt.labs.platform

Rectangle {
  radius: 3
  border.width: 1
  border.color: borderColor
  color: Material.background
  clip: true

  SplitView {
    id: splitViewTop
    orientation: Qt.Vertical
    width: parent.width
    height: parent.height * 0.95

    handle: Rectangle {
      id: handleDelegate
      implicitWidth: 1
      implicitHeight: 1
      containmentMask: Item {
        x: (handleDelegate.width - width) / 2
        width: splitViewTop.width
        height: 20
      }
    }

    Rectangle {
      id: listRect
      // radius: 5
      // border.width: 1
      // border.color: borderColor
      anchors.left: parent.left
      anchors.right: parent.right
      implicitHeight: (parent.height * 0.85) - 2
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
        anchors.bottomMargin: 0
        model: diskListModel
        Connections {
          target: diskListModel
          function onTransferChanged(transfer) {

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

    Rectangle {
      id: bottomRect
      anchors.left: parent.left
      anchors.right: parent.right
      height: parent.height * 0.15
      color: "transparent"
      // radius: 5
      // border.width: 1
      // border.color: borderColor
      Rectangle {
        id: destRect
        width: parent.width
        height: 45
        color: "transparent"
        clip: true
        // radius: 5
        // border.width: 1
        // border.color: borderColor
        TextField {
          id: destination
          width: (parent.width * 0.80) - appSpacing
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.bottom: parent.bottom
          placeholderText: "Destination"
          text: folderDialog.folder
          Component.onCompleted: font.pointSize = font.pointSize - 1.5
        }
        Button {
          text: "Select"
          width: 75
          height: parent.height * 0.80
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.bottom: parent.bottom
          onClicked: folderDialog.open()
          anchors.verticalCenter: parent.verticalCenter
        }
      }
      Rectangle {
        id: actionsRect
        // radius: 5
        // border.width: 1
        // border.color: borderColor
        anchors.top: destRect.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        width: 75 + 75 + 10
        height: 45
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
    }
  }

  Text {
    id: statusText
    text: "Ready"
    color: "white"
    anchors.top: splitViewTop.bottom
    anchors.left: parent.left
    anchors.margins: 5
    Component.onCompleted: statusText.font.pointSize = statusText.font.pointSize - 1.0
  }
}