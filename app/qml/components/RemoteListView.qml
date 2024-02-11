import QtQuick
import QtQuick.Shapes
import QtQuick.Dialogs
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {

  implicitWidth: parent.width / 2

  TextField {
    id: currentDirectory
    height: textFieldHeight
    enabled: false
    font.pointSize: 10
    anchors.margins: 10
    anchors.topMargin: 12
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    placeholderText: qsTr("Remote Directory")
    verticalAlignment: TextInput.AlignVCenter
    onAccepted: remoteFsModel.currentDirectory = currentDirectory.text
  }

  ListView {
    id: remoteListView
    clip: true
    focus: true
    currentIndex: -1
    cacheBuffer: 1024
    model: remoteFsModel
    anchors.leftMargin: 5
    anchors.rightMargin: 5
    anchors.left: parent.left
    delegate: listItemDelegate
    highlightMoveDuration: 100
    highlightMoveVelocity: 800
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    boundsBehavior: Flickable.StopAtBounds
    highlight: Rectangle { color: "lightsteelblue"; radius: 3 }
    height: parent.height - currentDirectory.height - spacer.height - statusRect.height - 2
    Connections {
      target: remoteFsModel
      function onConnected(isConnected) {
        if (!isConnected) {
          currentDirectory.text = ""
          status.text = "Not connected"
        }
        currentDirectory.enabled = isConnected
      }
      function onDirectoryList() {
        remoteListView.currentIndex = -1
        currentDirectory.text = remoteFsModel.currentDirectory
        var files, folders
        [files, folders] = remoteFsModel.totalFilesAndFolders.split(":")
        status.text = files + " files " + folders + " folders "
      }
    }
  }

  Rectangle {
    id: toolBar
    width: 26
    height: 175
    radius: 3
    border.width: 1
    border.color: borderColor
    color: Qt.lighter(Material.background, 1.8)
    visible: remoteFsModel.connected
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.rightMargin: 10
    anchors.topMargin: 7

    Image {
      id: downloadTool
      width: 18; height: 18
      source: "qrc:/download.png"
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 5
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Download")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: downloadTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: queueTool
      width: 18; height: 18
      source: "qrc:/addq.png"
      anchors.top: downloadTool.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 7
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Queue")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: queueTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: newTool
      width: 18; height: 18
      source: "qrc:/new.png"
      anchors.top: queueTool.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 7
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("New folder")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: newTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: renameTool
      width: 18; height: 18
      source: "qrc:/rename.png"
      anchors.top: newTool.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 5
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Rename")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: renameTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: deleteTool
      width: 18; height: 18
      source: "qrc:/filedelete.png"
      anchors.top: renameTool.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 5
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Delete")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: deleteTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: refreshTool
      width: 18; height: 18
      source: "qrc:/refresh.png"
      anchors.top: deleteTool.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 5
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Refresh")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: refreshTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: quitTool
      width: 18; height: 18
      source: "qrc:/exit.png"
      anchors.top: refreshTool.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 7
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: remoteFsModel.Quit()
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: quitTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
  }

  Rectangle {
    id: spacer
    color: Material.background
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: statusRect.top
    height: 3
    Shape {
      anchors.fill: spacer
      anchors.centerIn: spacer
      ShapePath {
        strokeColor: borderColor
        strokeStyle: ShapePath.SolidLine
        startX: 1; startY: 1
        PathLine {x: spacer.width; y: 1}
      }
    }
  }

  Rectangle {
    id: statusRect
    height: 25
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: 5
    anchors.rightMargin: 2
    color: Material.background
    // radius: 3
    // border.width: 1
    // border.color: borderColor

    Text {
      id: status
      color: textColor
      text: "Not connected"
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
    }
  }

  Component {
    id: listItemDelegate
    Rectangle {
      id: delegateRect
      implicitWidth: ListView.view.width
      implicitHeight: 24
      color: "transparent"
      // radius: 3
      // border.width: 1
      // border.color: "#123"

      Image {
        id: listItemIcon
        x: 3
        width: 20; height: 20
        anchors.verticalCenter: parent.verticalCenter
        source: fileIsDir ? (fileName !== "." ? "qrc:/folder.png" : "") : "qrc:/file.png"
      }

      Text {
        id: feText
        x: listItemIcon.x + listItemIcon.width + 5
        text: fileName
        height: parent.height
        color: delegateRect.ListView.isCurrentItem ? "black" : textColor
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: {
          if (fileIsDir) {
            if (fileName === "..")
              remoteFsModel.currentDirectory = remoteFsModel.getParentDirectory()
            else
              remoteFsModel.currentDirectory = remoteFsModel.currentDirectory +
                (remoteFsModel.currentDirectory.endsWith("/") ? fileName : ("/" + fileName))
          }
        }
        onClicked: (mouse) => {
          remoteListView.currentIndex = index
        }
      }
    }
  }

  function processToolBarAction(action) {

    var fileName = remoteFsModel.get(remoteListView.currentIndex, "fileName")
    var fileIsDir = remoteFsModel.get(remoteListView.currentIndex, "fileIsDir")
    var fileSize = remoteFsModel.get(remoteListView.currentIndex, "fileSize")

    switch (action)
    {
      case "Queue":
      case "Download":
      {
        if (!remoteFsModel.connected) {
          logger.updateStatus(1, "Please connect to a server first")
          return;
        }

        if (remoteListView.currentIndex < 0) {
          logger.updateStatus(1, "Please select a file to " + action.toLowerCase())
          return;
        }

        remoteFsModel.QueueTransfer(remoteListView.currentIndex, action === "Download")

        return;
      }

      case "Delete":
      {
        if (!remoteFsModel.connected) {
          logger.updateStatus(1, "Please connect to a server first")
          return;
        }

        if (remoteListView.currentIndex < 0) {
          logger.updateStatus(1, "Please select a file to delete")
          return;
        }

        newRenamePopup.context = "Delete \"" + fileName + "\""
        newRenamePopup.elementName = fileName
        newRenamePopup.elementIsDir = fileIsDir
        newRenamePopup.inputHint = "Folder name"
        newRenamePopup.inputValue = fileName
        newRenamePopup.open()

        return;
      }

      case "New folder":
      {
        if (!remoteFsModel.connected) {
          logger.updateStatus(1, "Please connect to a server first")
          return;
        }

        newRenamePopup.context = "New folder"
        newRenamePopup.inputHint = "Folder name"
        newRenamePopup.inputValue = ""
        newRenamePopup.open()
        return;
      }

      case "Rename":
      {
        if (!remoteFsModel.connected) {
          logger.updateStatus(1, "Please connect to a server first")
          return;
        }

        if (remoteListView.currentIndex < 0) {
          logger.updateStatus(1, "Please select a file to rename")
          return;
        }

        newRenamePopup.context = "Rename \"" + fileName + "\""
        newRenamePopup.elementName = fileName
        newRenamePopup.inputHint = "New name"
        newRenamePopup.inputValue = ""
        newRenamePopup.open()
        return;
      }

      case "Refresh":
      {
        remoteFsModel.currentDirectory = remoteFsModel.currentDirectory
      }
    }
  }

  RenameNewPopup {
    id: newRenamePopup
    parent: remoteListView
    context: ""
    elementName: ""
    elementIsDir: ""
    onDismissed: (userInput) => {
      newRenamePopup.close()
      if (userInput.length)
      {
        if (context.startsWith("New folder"))
        {
          remoteFsModel.CreateDirectory(userInput)
        }
        else if (context.startsWith("Rename"))
        {
          remoteFsModel.Rename(elementName, userInput)
        }
        else if (context.startsWith("Delete"))
        {
          var path = remoteFsModel.currentDirectory +
            (remoteFsModel.currentDirectory.endsWith("/") ? userInput : ("/" + userInput))
          if (elementIsDir) {
            remoteFsModel.RemoveDirectory(path)
          } else {
            remoteFsModel.RemoveFile(path)
            remoteFsModel.currentDirectory = remoteFsModel.currentDirectory
          }
        }
      }
    }
  }

  Login {
    visible: !remoteFsModel.connected
    width: parent.width - 100
    anchors.top: currentDirectory.bottom
    anchors.topMargin: 45
    anchors.horizontalCenter: parent.horizontalCenter
    onLogin: (host, port, user, password, protocol) => {
      remoteFsModel.Connect(host, port, user, password, protocol)
    }
  }

  Component.onCompleted: {}
}