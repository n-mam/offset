import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls

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
      placeholderText: qsTr("Remote Directory")
      horizontalAlignment: Text.AlignLeft
      verticalAlignment: TextInput.AlignVCenter
      onAccepted: {
        ftpModel.currentDirectory = currentDirectory.text
      }
      Component.onCompleted: font.pointSize = font.pointSize - 1.5
    }

    ListView {
      id: remoteListView
      width: parent.width
      height: ftpModel.connected ? parent.height * 0.89 : 0
      anchors.top: currentDirectory.bottom
      clip: true
      model: ftpModel
      delegate: listItemDelegate
      Connections {
        target: ftpModel
        function onDirectoryList() {
          currentDirectory.text = ftpModel.currentDirectory
          var files, folders
          [files, folders] = ftpModel.totalFilesAndFolders.split(":")
          status.text = files + " files " + folders + " folders "
        }
      }
    }

    Login {
      visible: !ftpModel.connected
      anchors.margins: 90
      width: parent.width - 10
      anchors.top: currentDirectory.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      onLogin: (host, port, user, password) => {
        ftpModel.Connect(host, port, user, password, "ftps");
      }
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
        text: "Not connected"
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
        source: fileIsDir ? (fileName !== "." ? "qrc:/folder.png" : "") : "qrc:/file.png"
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
          var path = ftpModel.currentDirectory + "/" + feText.text
          fileIsDir ? ftpModel.RemoveDirectory(path) :
            ftpModel.RemoveFile(path)
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
              ftpModel.CreateDirectory(userInput)
            }
            else if (context.startsWith("Rename"))
            {
              ftpModel.Rename(feText.text, userInput)
            }
          }      
        }
      }

      ContextMenuPopup {
        id: contextMenu
        parent: feText
        context: feText.text
        menu: ["Download", "Rename", "Delete", "Refresh", "New folder"]
        onClosed: {
          feText.color = "white"
          delegateRect.color = Material.background
        }
        onMenuItemActivated: (action, context) => {
          feText.color = "white"
          delegateRect.color = Material.background
          contextMenu.close()
          console.log(action, context, fileIsDir)

          var path = ftpModel.currentDirectory + "/" + context

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
          else if (action === "Refresh")
          {
            ftpModel.currentDirectory = ftpModel.currentDirectory
          }
        }
      }

      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onDoubleClicked: {
          if (fileIsDir) {
            if (fileName === "..")
              ftpModel.currentDirectory = getParentFolder()
            else
              ftpModel.currentDirectory = ftpModel.currentDirectory + 
                (ftpModel.currentDirectory.endsWith("/") ? fileName : ("/" + fileName))
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

  function getParentFolder() {
    var tokens = ftpModel.currentDirectory.split("/");
    tokens.pop()
    var parentFolder = "";
    for (var e of tokens) {
      if (e.length) 
        parentFolder += ("/" + e)
    }
    if (!parentFolder.length) parentFolder = "/"
    return parentFolder
  }

  function urlToPath(url) {
    var path = url.toString();
    path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
    return decodeURIComponent(path).replace(/\//g, "\\") 
  }

  Component.onCompleted: {
    
  }
}