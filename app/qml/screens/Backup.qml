import QtQuick
import QtQuick.Controls
import Qt.labs.platform
import "qrc:/components"

Rectangle {
  radius: 3
  border.width: 1
  border.color: borderColor
  color: Material.background

  SplitView {
    id: splitViewTop
    orientation: Qt.Vertical
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: fxcFooter.top

    handle: Rectangle {
      id: handleDelegate
      implicitWidth: 1
      implicitHeight: 1
      containmentMask: Item {
        x: (handleDelegate.width - width) / 2
        width: splitViewTop.width
        height: 15
      }
    }

    Rectangle {
      id: listRect
      // radius: 5
      // border.width: 1
      // border.color: borderColor
      width: parent.width
      SplitView.preferredHeight: (parent.height * 0.79) - 2
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
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            diskListModel.refreshModel()
          }
        }
      }
      List {
        anchors.fill: parent
        anchors.margins: 10
        anchors.bottomMargin: 1
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
      width: parent.width
      SplitView.minimumHeight: 90
      SplitView.preferredHeight: parent.height * 0.20
      SplitView.maximumHeight: 100
      color: "transparent"
      // radius: 5
      // border.width: 1
      // border.color: borderColor
      Rectangle {
        id: destRect
        width: parent.width
        height: 40
        anchors.top: parent.top
        anchors.topMargin: 8
        color: "transparent"
        // radius: 5
        // border.width: 1
        // border.color: borderColor
        TextField {
          id: destination
          width: (parent.width * 0.77) - (2 * appSpacing)
          height: parent.height * 0.85
          anchors.left: parent.left
          anchors.leftMargin: 7
          placeholderText: "Destination"
          text: folderDialog.folder
          anchors.verticalCenter: parent.verticalCenter
        }
        Button {
          text: "Select"
          width: (parent.width * 0.20) - appSpacing
          height: parent.height
          anchors.right: parent.right
          anchors.rightMargin: 7
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
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        width: parent.width * 0.5
        height: 40
        Button {
          id: startButton
          text: "START"
          enabled: (diskListModel.transfer === 0)
          width: parent.width * 0.45
          height: parent.height
          anchors.left: parent.left
          anchors.margins: appSpacing
          anchors.verticalCenter: parent.verticalCenter
          onClicked: {
            diskListModel.convertSelectedItemsToVirtualDisks(destination.text)
          }
        }
        Button {
          id: cancelbutton
          text: "CANCEL"
          enabled: (diskListModel.transfer !== 0)
          width: parent.width * 0.45
          height: parent.height
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

  FxcFooter {
    id: fxcFooter
    height: 25
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    Connections {
      target: logger
      function onUpdateStatus(key, status) {
        if (key === 0) {
          fxcFooter.currentStatus = status
        }
      }
    }
  }

}