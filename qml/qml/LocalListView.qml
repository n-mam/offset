import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls
import Qt.labs.folderlistmodel

Item {

  implicitWidth: parent.width / 2

  Rectangle {
    id: listRectangle
    anchors.fill: parent
    anchors.margins: 5
    // radius: 2
    // border.width: 1
    // border.color: borderColor
    color: Material.background

    TextField {
      id: currentDirectory
      width: parent.width
      height: parent.height * 0.08
      placeholderText: qsTr("Local Directory")
      verticalAlignment: TextInput.AlignVCenter
      onAccepted: {
        folderModel.folder = "file:///" + currentDirectory.text
      }
      Component.onCompleted: font.pointSize = font.pointSize - 1.5
    }

    ListView {
      id: localListView
      width: parent.width
      height: parent.height * 0.89
      anchors.top: currentDirectory.bottom
      clip: true
      model: folderModel
      delegate: listItemDelegate
    }

    Rectangle {
      width: parent.width
      height: parent.height * 0.05
      anchors.bottom: parent.bottom
      color: Material.background
      // radius: 2
      // border.width: 1
      // border.color: borderColor

      Text {
        id: status
        color: "white"
        text: "Total Items : " + (folderModel.count - 2)
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  Component {
    id: listItemDelegate
    Rectangle {
      id: delegateRect
      width: ListView.view.width
      height: fileName === "." ? 0 : 26
      // radius: 2
      // border.width: 1
      // border.color: "#123"
      color: Material.background
      Image {
        id: listItemIcon
        x: parent.x + 3
        width: 16; height: 16
        anchors.verticalCenter: parent.verticalCenter
        source: model.fileIsDir ? (fileName !== "." ? "qrc:/folder.png" : "") : "qrc:/file.png"
      }

      Text {
        id: feText
        x: listItemIcon.x + listItemIcon.width + 5
        text: fileName
        height: parent.height
        color: "white"
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
          console.log(action, context, fileIsDir)

          var path = currentDirectory.text + "/" + context

          if (action === "Delete")
          {
            warningDialog.open();
          }
          else if (action === "Download")
          {

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
        hoverEnabled: true
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onDoubleClicked: {
          if (model.fileIsDir) {
            if (fileName === "..")
              folderModel.folder = folderModel.parentFolder
            else
              folderModel.folder = folderModel.folder + "/" + fileName
            currentDirectory.text = urlToPath(folderModel.folder)
          }
        }
        onClicked: (mouse) => {
          if (mouse.button == Qt.RightButton && fileName !== "..") {
            delegateRect.color = "#A3CCAB"
            feText.color = "black"
            contextMenu.x = mouse.x - feText.x
            contextMenu.y = mouse.y
            contextMenu.open()
          }
        }
      }
    }
  }

  FolderListModel {
    id: folderModel
    showDirs: true
    showDirsFirst: true
    showDotAndDotDot: true
  }

  function urlToPath(url) {
    var path = url.toString();
    path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
    return decodeURIComponent(path).replace(/\//g, "\\") 
  }

  Component.onCompleted: {
    currentDirectory.text = urlToPath(folderModel.folder)
  }
}