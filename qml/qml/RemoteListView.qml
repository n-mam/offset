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
      height: parent.height * 0.10
      placeholderText: qsTr("Remote Directory")
      verticalAlignment: TextInput.AlignVCenter
      onAccepted: {
        ftpModel.remoteDirectory = currentDirectory.text
      }
      Component.onCompleted: font.pointSize = font.pointSize - 1.5
    }

    ListView {
      id: remoteListView
      width: parent.width
      height: ftpModel.connected ? parent.height * 0.86 : 0
      anchors.top: currentDirectory.bottom
      clip: true
      model: ftpModel
      delegate: listItemDelegate
      cacheBuffer: 1024
      highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
      Connections {
        target: ftpModel
        function onDirectoryList() {
          remoteListView.currentIndex = -1
          currentDirectory.text = ftpModel.remoteDirectory
          var files, folders
          [files, folders] = ftpModel.totalFilesAndFolders.split(":")
          status.text = files + " files " + folders + " folders "
        }
      }
    }

    Component {
      id: listItemDelegate
      Rectangle {
        id: delegateRect
        width: ListView.view.width
        height: 26
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
            var path = ftpModel.remoteDirectory + "/" + feText.text
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

            console.log(action, fileName, fileIsDir)

            var path = ftpModel.remoteDirectory + 
                           (ftpModel.remoteDirectory.endsWith("/") ? 
                              fileName : ("/" + fileName))

            if (action === "Delete")
            {
              warningDialog.open();
            }
            else if (action === "Download")
            {
              ftpModel.Download(fileName, ftpModel.remoteDirectory, ftpModel.localDirectory, fileIsDir)
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
              ftpModel.remoteDirectory = ftpModel.remoteDirectory
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onDoubleClicked: {
            if (fileIsDir) {
              if (fileName === "..")
                ftpModel.remoteDirectory = getParentFolder()
              else
                ftpModel.remoteDirectory = ftpModel.remoteDirectory + 
                  (ftpModel.remoteDirectory.endsWith("/") ? fileName : ("/" + fileName))
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
      anchors.top: remoteListView.bottom
      color: "transparent"
      // radius: 2
      // border.width: 1
      // border.color: borderColor

      Text {
        id: status
        color: "white"
        text: "Not connected"
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  function getParentFolder() {
    var tokens = ftpModel.remoteDirectory.split("/");
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
    console.log(remoteListView.cacheBuffer)
  }
}