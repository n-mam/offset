import QtQuick
import QtQuick.Shapes
import QtQuick.Dialogs
import QtQuick.Controls

Item {

  implicitWidth: parent.width / 2

  TextField {
    id: currentDirectory
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 5
    height: 43
    enabled: false
    placeholderText: qsTr("Remote Directory")
    verticalAlignment: TextInput.AlignVCenter
    onAccepted: {
      ftpModel.remoteDirectory = currentDirectory.text
    }
    Component.onCompleted: font.pointSize = font.pointSize - 1.5
  }

  ListView {
    id: remoteListView
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.leftMargin: 5
    anchors.rightMargin: 5
    height: parent.height - currentDirectory.height - spacer.height - statusRect.height - 2
    clip: true
    model: ftpModel
    delegate: listItemDelegate
    cacheBuffer: 1024
    focus: true
    highlightMoveDuration: 100
    highlightMoveVelocity: 800
    highlight: Rectangle { color: "lightsteelblue"; radius: 2 }
    Connections {
      target: ftpModel
      function onConnected(isConnected) {
        if (!isConnected) {
          currentDirectory.text = ""
          status.text = "Not connected"
        }
        quit.visible = currentDirectory.enabled = isConnected
      }
      function onDirectoryList() {
        remoteListView.currentIndex = -1
        currentDirectory.text = ftpModel.remoteDirectory
        var files, folders
        [files, folders] = ftpModel.totalFilesAndFolders.split(":")
        status.text = files + " files " + folders + " folders "
      }
    }
  }

  Login {
    visible: !ftpModel.connected
    width: parent.width - 30
    anchors.top: currentDirectory.bottom
    anchors.topMargin: 45
    anchors.horizontalCenter: parent.horizontalCenter
    onLogin: (host, port, user, password, protocol) => {
      ftpModel.Connect(host, port, user, password, protocol)
    }
  }

  Image {
    id: quit
    width: 18; height: 18
    visible: false
    source: "qrc:/exit.png" 
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.rightMargin: 5
    MouseArea {
      anchors.fill: parent
      onClicked: ftpModel.Quit()
    }
  }

  Rectangle {
    id: spacer
    color: "transparent"
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: remoteListView.bottom
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
      text: "Not connected"
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 5
    }
  }

  Component {
    id: listItemDelegate
    Rectangle {
      id: delegateRect
      width: ListView.view.width
      height: 24
      color: "transparent"
      // radius: 2
      // border.width: 1
      // border.color: "#123"

      Image {
        id: listItemIcon
        x: 3
        width: 18; height: 18
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
        anchors.verticalCenter: parent.verticalCenter
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
        menu: ["Queue", "Rename", "Delete", "Refresh", "New folder"]
        onClosed: {
        }
        onMenuItemActivated: (action, context) => {

          contextMenu.close()

          var path = ftpModel.remoteDirectory + 
                          (ftpModel.remoteDirectory.endsWith("/") ? 
                            fileName : ("/" + fileName))

          if (action === "Queue")
          {
            ftpModel.Transfer(fileName, ftpModel.remoteDirectory, ftpModel.localDirectory, fileIsDir, false, fileSize)
          }
          else if (action === "Delete")
          {
            warningDialog.open();
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
          remoteListView.currentIndex = index
          if (mouse.button == Qt.RightButton && fileName !== "..") {
            contextMenu.x = mouse.x - feText.x
            contextMenu.y = mouse.y
            contextMenu.open()
          }
        }
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
  }
}