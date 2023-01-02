import QtQuick
import QtQuick.Shapes
import QtQuick.Dialogs
import QtQuick.Controls
import Qt.labs.folderlistmodel

Item {

  implicitWidth: parent.width / 2

  TextField {
    id: currentDirectory
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 5
    height: 43
    placeholderText: qsTr("Local Directory")
    verticalAlignment: TextInput.AlignVCenter
    onAccepted: {
      folderModel.folder = "file:///" + currentDirectory.text
    }
    Component.onCompleted: font.pointSize = font.pointSize - 1.5
  }

  ListView {
    id: localListView
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.leftMargin: 5
    anchors.rightMargin: 5
    height: parent.height - currentDirectory.height - - spacer.height - statusRect.height
    clip: true
    model: folderModel
    delegate: listItemDelegate
    cacheBuffer: 1024
    highlightMoveDuration: 100
    highlightMoveVelocity: 800
    highlight: Rectangle { color: "lightsteelblue"; radius: 2 }
  }

  Rectangle {
    id: spacer
    color: "transparent"
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: localListView.bottom
    height: 1
    Shape {
      anchors.fill: spacer
      anchors.centerIn: spacer
      ShapePath {
        strokeWidth: 1
        strokeColor: "white"
        strokeStyle: ShapePath.SolidLine
        startX: 0; startY: 0
        PathLine {x: spacer.width; y: 0}
      }
    }
  }

  Rectangle {
    id: statusRect
    width: parent.width
    height: 25
    anchors.bottom: parent.bottom
    color: "transparent"
    // radius: 2
    // border.width: 1
    // border.color: borderColor

    Text {
      id: status
      color: "white"
      text: "Total Items : " + (folderModel.count - 2)
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 5
    }
  }

  FolderListModel {
    id: folderModel
    showDirs: true
    showDirsFirst: true
    showDotAndDotDot: true
    //onFolderChanged: console.log("new local folder set to " + folder);
    onStatusChanged: () => {
      if (folderModel.status == FolderListModel.Ready) {
        localListView.currentIndex = -1
        currentDirectory.text = urlToPath(folderModel.folder)
        ftpModel.setLocalDirectory(currentDirectory.text);
      }
    }
  }

  Component {
    id: listItemDelegate
    Rectangle {
      id: delegateRect
      width: ListView.view.width
      height: 26
      Component.onCompleted: {
        if (fileName === ".") {
          height = 0
          visible = false
        }
      }
      color: "transparent"
      // radius: 2
      // border.width: 1
      // border.color: "#123"

      Image {
        id: listItemIcon
        x: 3
        width: 16; height: 16
        anchors.verticalCenter: parent.verticalCenter
        source: fileIsDir ? (fileName !== "." ? "qrc:/folder.png" : "") : "qrc:/file.png"
      }

      Text {
        id: feText
        x: listItemIcon.x + listItemIcon.width + 5
        text: fileName
        height: parent.height
        color: delegateRect.ListView.isCurrentItem ? "black" : "white"
        verticalAlignment: Text.AlignVCenter
      }

      MessageDialog {
        id: warningDialog
        text: "WARNING"
        informativeText: "Do you really want to delete ?"
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        onAccepted: () => {
          var path = currentDirectory.text + "/" + feText.text
          fileIsDir ? ftpModel.RemoveDirectory(path, true) :
            ftpModel.RemoveFile(path, true)
        }
      }

      RenameNewPopup {
        id: newRenamePopup
        parent: feText
        context: ""
        onDismissed: (userInput) => {
          newRenamePopup.close()
          if (userInput.length)
          {
            if (context.startsWith("New folder"))
            {
              ftpModel.CreateDirectory(currentDirectory.text + "/" + userInput, true)
            }
            else if (context.startsWith("Rename"))
            {
              ftpModel.Rename(
                currentDirectory.text + "/" + feText.text,
                currentDirectory.text + "/" + userInput, true)
            }
          }
        }
      }

      ContextMenuPopup {
        id: contextMenu
        parent: feText
        context: feText.text
        menu: ["Upload", "Rename", "Delete", "New folder"]
        onClosed: {
          feText.color = "white"
          delegateRect.color = Material.background
        }
        onMenuItemActivated: (action, context) => {
          feText.color = "white"
          delegateRect.color = Material.background
          contextMenu.close()

          if (action === "Delete")
          {
              warningDialog.open();
          }
          else if (action === "Upload" && ftpModel.connected)
          {
            ftpModel.Transfer(fileName, ftpModel.localDirectory, ftpModel.remoteDirectory, fileIsDir, true, fileSize)
          }
          else if (action === "Rename")
          {
            newRenamePopup.context = "Rename \"" + fileName + "\""
            newRenamePopup.open()
          }
          else if (action === "New folder")
          {
            newRenamePopup.context = "New folder"
            newRenamePopup.open()
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: {
          if (fileIsDir) {
            if (fileName === "..")
              folderModel.folder = folderModel.parentFolder
            else
              folderModel.folder = "file:///" + currentDirectory.text + "/" + fileName                       
          }
        }
        onClicked: (mouse) => {
          delegateRect.ListView.view.currentIndex = index
          if (mouse.button == Qt.RightButton && fileName !== "..") {
            contextMenu.x = mouse.x - feText.x
            contextMenu.y = mouse.y
            contextMenu.open()
          }
        }
      }
    }
  }

  function urlToPath(url) {
    var path = url.toString();
    path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
    return decodeURIComponent(path).replace(/\//g, "\\") 
  }

  Component.onCompleted: {
  }
}