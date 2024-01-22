import QtQuick
import QtQuick.Controls
import Qt.labs.platform
import "qrc:/components"

Rectangle {
  radius: 3
  border.width: 1
  border.color: borderColor
  color: Material.background

  Column {
    id: bottomRect
    spacing: appSpacing
    anchors.fill: parent

    List {
      width: parent.width
      model: diskListModel
      height: parent.height - actionsRect.height - destinationSelector.height - fxcFooter.height - (3 *appSpacing)
      Connections {
        target: diskListModel
        function onTransferChanged(transfer) {

        }
      }
    }

    FileFolderSelector {
      id: destinationSelector
      height: 28
      width: 380
      isFolderSelector: true
      image: "qrc:/folder.png"
      placeholder: "Destination"
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      id: actionsRect
      spacing: appSpacing
      height: 28
      anchors.horizontalCenter: parent.horizontalCenter
      ButtonX {
        id: startButton
        width: 100
        text: "START"
        height: parent.height
        enabled: (diskListModel.transfer === 0)
        onButtonXClicked: {
          diskListModel.convertSelectedItemsToVirtualDisks(destination.text)
        }
      }
      ButtonX {
        id: cancelbutton
        width: 100
        text: "CANCEL"
        height: parent.height
        enabled: (diskListModel.transfer !== 0)
        onButtonXClicked: {
          diskListModel.stop = true;
        }
      }
    }

    FxcFooter {
      id: fxcFooter
      height: 25
      width: parent.width
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

  ButtonX {
      z: 2
      text: "R"
      width: 20
      height: 20
      anchors.top: parent.top
      anchors.right: parent.right
      onButtonXClicked: diskListModel.refreshModel()
  }
}