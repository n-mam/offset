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
      border.color: borderColor
      containmentMask: Item {
        x: (handleDelegate.width - width) / 2
        width: splitViewTop.width
        height: 15
      }
    }

    Rectangle {
      id: listRect
      // radius: 3
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
          color: textColor
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
    }

    Rectangle {
      id: bottomRect
      width: parent.width
      color: "transparent"
      SplitView.minimumHeight: 90
      SplitView.maximumHeight: 100
      SplitView.preferredHeight: parent.height * 0.20
      // radius: 3
      // border.width: 1
      // border.color: borderColor

      FileFolderSelector {
        height: 43
        width: parent.width / 2
        isFolderSelector: true
        image: "qrc:/folder.png"
        placeholder: "Destination"
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Rectangle {
        id: actionsRect
        // radius: 3
        // border.width: 1
        // border.color: borderColor
        height: 36
        color: "transparent"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: startButton.width + cancelbutton.width + 4
        ButtonX {
          id: startButton
          width: 100
          text: "START"
          height: parent.height
          enabled: (diskListModel.transfer === 0)
          anchors.verticalCenter: parent.verticalCenter
          onButtonXClicked: {
            diskListModel.convertSelectedItemsToVirtualDisks(destination.text)
          }
        }
        ButtonX {
          id: cancelbutton
          width: 100
          text: "CANCEL"
          anchors.margins: 4
          height: parent.height
          anchors.left: startButton.right
          enabled: (diskListModel.transfer !== 0)
          anchors.verticalCenter: parent.verticalCenter
          onButtonXClicked: {
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