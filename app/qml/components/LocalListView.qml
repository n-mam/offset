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
    font.pointSize: 10
    anchors.margins: 10
    anchors.topMargin: 12
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    placeholderText: qsTr("Local Directory")
    verticalAlignment: TextInput.AlignVCenter
    onAccepted: localFsModel.currentDirectory = currentDirectory.text
  }

  ListView {
    id: localListView
    clip: true
    focus: true
    currentIndex: -1
    cacheBuffer: 1024
    model: localFsModel
    anchors.topMargin: 7
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
      target: localFsModel
      function onDirectoryList() {
        localListView.currentIndex = -1
        currentDirectory.text = localFsModel.currentDirectory
        var files, folders
        [files, folders] = localFsModel.totalFilesAndFolders.split(":")
        status.text = files + " files " + folders + " folders "
      }
    }
  }

  Rectangle {
    id: toolBar
    width: 26
    height: 147
    radius: 3
    border.width: 1
    border.color: borderColor
    color: Qt.lighter(Material.background, 1.8)
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.rightMargin: 10
    anchors.topMargin: 7

    Image {
      id: uploadTool
      width: 18; height: 18
      source: "qrc:/upload.png"
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.margins: 5
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Upload")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: uploadTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: queueTool
      width: 18; height: 18
      source: "qrc:/addq.png"
      anchors.top: uploadTool.bottom
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
      anchors.margins: 7
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: processToolBarAction("Rename")
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: renameTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
    Image {
      id: refreshTool
      width: 18; height: 18
      source: "qrc:/refresh.png"
      anchors.top: renameTool.bottom
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
      id: deleteTool
      width: 18; height: 18
      source: "qrc:/filedelete.png"
      anchors.top: refreshTool.bottom
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
      Component.onCompleted: {
        if (fileName === ".") {
          height = 0
          visible = false
        }
      }
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
        text: fileName
        font.pointSize: 10
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        x: listItemIcon.x + listItemIcon.width + 5
        anchors.verticalCenter: parent.verticalCenter
        color: delegateRect.ListView.isCurrentItem ? "black" : textColor
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: {
          if (fileIsDir) {
            if (fileName === "..")
              localFsModel.currentDirectory = localFsModel.getParentDirectory()
            else
              localFsModel.currentDirectory = localFsModel.currentDirectory +
                (localFsModel.currentDirectory.endsWith(localFsModel.pathSeperator) ?
                  fileName : (localFsModel.pathSeperator + fileName))
          }
        }
        onClicked: (mouse) => {
          localListView.currentIndex = index
        }
      }
    }
  }

  function processToolBarAction(action)
  {
    var fileName = localFsModel.get(localListView.currentIndex, "fileName")
    var fileIsDir = localFsModel.get(localListView.currentIndex, "fileIsDir")
    var fileSize = localFsModel.get(localListView.currentIndex, "fileSize")

    switch (action)
    {
      case "Queue":
      case "Upload":
      {
        if (!remoteFsModel.connected) {
          logger.updateStatus(1, "Please connect to a server first")
          return;
        }

        if (localListView.currentIndex < 0) {
          logger.updateStatus(1, "Please select a file to upload")
          return;
        }

        localFsModel.QueueTransfer(localListView.currentIndex, action === "Upload")

        return;
      }

      case "Delete":
      {
        if (localListView.currentIndex < 0) {
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
        newRenamePopup.context = "New folder"
        newRenamePopup.inputHint = "Folder name"
        newRenamePopup.inputValue = ""
        newRenamePopup.open()
        return;
      }

      case "Rename":
      {
        if (localListView.currentIndex < 0) {
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
        localFsModel.currentDirectory = localFsModel.currentDirectory
      }
    }
  }

  RenameNewPopup {
    id: newRenamePopup
    parent: localListView
    context: ""
    elementName: ""
    elementIsDir: ""
    onDismissed: (userInput) => {
      newRenamePopup.close()
      if (userInput.length)
      {
        if (context.startsWith("New folder"))
        {
          localFsModel.CreateDirectory(currentDirectory.text + "/" + userInput, true)
        }
        else if (context.startsWith("Rename"))
        {
          localFsModel.Rename(
            currentDirectory.text + "/" + elementName,
            currentDirectory.text + "/" + userInput, true)
        }
        else if (context.startsWith("Delete"))
        {
          var path = currentDirectory.text + "/" + elementName
          elementIsDir ? localFsModel.RemoveDirectory(path, true) :
            localFsModel.RemoveFile(path, true)
        }
        localFsModel.currentDirectory = localFsModel.currentDirectory
      }
    }
  }

  Component.onCompleted: localFsModel.currentDirectory = ""
}