import QtQuick
import QtQuick.Shapes
import QtQuick.Dialogs
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {

  implicitWidth: parent.width / 2

  TextField {
    id: currentDirectory
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.topMargin: 12
    anchors.margins: 5
    height: 43
    enabled: false
    placeholderText: qsTr("Remote Directory")
    verticalAlignment: TextInput.AlignVCenter
    onAccepted: ftpModel.currentDirectory = currentDirectory.text
  }

  ListView {
    id: remoteListView
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.leftMargin: 5
    anchors.rightMargin: 5
    boundsBehavior: Flickable.StopAtBounds
    height: parent.height - currentDirectory.height - spacer.height - statusRect.height - 2
    clip: true
    model: ftpModel
    delegate: listItemDelegate
    currentIndex: -1
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
        currentDirectory.enabled = isConnected
      }
      function onDirectoryList() {
        remoteListView.currentIndex = -1
        currentDirectory.text = ftpModel.currentDirectory
        var files, folders
        [files, folders] = ftpModel.totalFilesAndFolders.split(":")
        status.text = files + " files " + folders + " folders "
      }
    }
  }

  Rectangle {
    id: toolBar
    width: 26
    height: 175
    radius: 2
    border.width: 1
    border.color: borderColor
    color: Qt.lighter(Material.background, 1.8)
    visible: ftpModel.connected
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.rightMargin: 5
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
        onClicked: ftpModel.Quit()
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: quitTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
  }

  function processToolBarAction(action) {

    var fileName = ftpModel.get(remoteListView.currentIndex, "fileName")
    var fileIsDir = ftpModel.get(remoteListView.currentIndex, "fileIsDir")
    var fileSize = ftpModel.get(remoteListView.currentIndex, "fileSize")

    switch (action)
    {
      case "Queue":
      case "Download":
      {
        if (!ftpModel.connected) {
          logger.updateStatus(1, "Please connect to a server first")
          return;
        }

        if (remoteListView.currentIndex < 0) {
          logger.updateStatus(1, "Please select a file to " + action.toLowerCase())
          return;
        }

        ftpModel.QueueTransfer(remoteListView.currentIndex, action === "Download")

        return;
      }

      case "Delete":
      {
        if (!ftpModel.connected) {
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
        if (!ftpModel.connected) {
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
        if (!ftpModel.connected) {
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
        ftpModel.currentDirectory = ftpModel.currentDirectory
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
          ftpModel.CreateDirectory(userInput)
        }
        else if (context.startsWith("Rename"))
        {
          ftpModel.Rename(elementName, userInput)
        }
        else if (context.startsWith("Delete"))
        {
          var path = ftpModel.currentDirectory +
            (ftpModel.currentDirectory.endsWith("/") ? userInput : ("/" + userInput))
          if (elementIsDir) {
            ftpModel.RemoveDirectory(path)
          } else {
            ftpModel.RemoveFile(path)
            ftpModel.currentDirectory = ftpModel.currentDirectory
          }
        }
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

  Rectangle {
    id: spacer
    color: "transparent"
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: statusRect.top
    height: 1
    Shape {
      anchors.fill: spacer
      anchors.centerIn: spacer
      ShapePath {
        strokeWidth: 1
        strokeColor: "white"
        strokeStyle: ShapePath.SolidLine
        startX: 1; startY: 0
        PathLine {x: spacer.width; y: 0}
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
    }
  }

  Component {
    id: listItemDelegate
    Rectangle {
      id: delegateRect
      implicitWidth: ListView.view.width
      implicitHeight: 24
      color: "transparent"
      // radius: 2
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
        color: delegateRect.ListView.isCurrentItem ? "black" : "white"
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: {
          if (fileIsDir) {
            if (fileName === "..")
              ftpModel.currentDirectory = ftpModel.getParentDirectory()
            else
              ftpModel.currentDirectory = ftpModel.currentDirectory +
                (ftpModel.currentDirectory.endsWith("/") ? fileName : ("/" + fileName))
          }
        }
        onClicked: (mouse) => {
          remoteListView.currentIndex = index
        }
      }
    }
  }

  Component.onCompleted: {}
}