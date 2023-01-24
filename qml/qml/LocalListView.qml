import QtQuick
import QtQuick.Shapes
import QtQuick.Dialogs
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects

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
    boundsBehavior: Flickable.StopAtBounds
    height: parent.height - currentDirectory.height - spacer.height - statusRect.height - 2
    clip: true
    model: folderModel
    delegate: listItemDelegate
    currentIndex: -1
    cacheBuffer: 1024
    focus: true
    highlightMoveDuration: 100
    highlightMoveVelocity: 800
    highlight: Rectangle { color: "lightsteelblue"; radius: 2 }
  }

  Rectangle {
    id: toolBar
    width: 26
    height: 125
    radius: 2
    border.width: 1
    border.color: borderColor
    color: Qt.lighter(Material.background, 1.8)
    anchors.right: parent.right
    anchors.top: currentDirectory.bottom
    anchors.rightMargin: 5

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
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
        onContainsMouseChanged: deleteTool.scale = 1 + (containsMouse ? 0.2 : 0)
      }
    }
  }

  function processToolBarAction(action) {

    var fileName = folderModel.get(localListView.currentIndex, "fileName")
    var fileIsDir = folderModel.get(localListView.currentIndex, "fileIsDir")
    var fileSize = folderModel.get(localListView.currentIndex, "fileSize")

    if (action === "Upload" && ftpModel.connected && remoteListView.currentIndex >= 0)
    {

    }
    else if (action === "Queue" && ftpModel.connected && localListView.currentIndex >= 0)
    {
      ftpModel.Transfer(fileName, ftpModel.localDirectory, ftpModel.remoteDirectory, fileIsDir, true, fileSize)
    }
    else if (action === "Delete" && localListView.currentIndex >= 0)
    {
      newRenamePopup.context = "Delete \"" + fileName + "\""
      newRenamePopup.elementName = fileName
      newRenamePopup.elementIsDir = fileIsDir
      newRenamePopup.inputHint = "Folder name"
      newRenamePopup.inputValue = fileName
      newRenamePopup.open()
    }
    else if (action === "Rename" && localListView.currentIndex >= 0)
    {
      newRenamePopup.context = "Rename \"" + fileName + "\""
      newRenamePopup.elementName = fileName
      newRenamePopup.inputHint = "New name"
      newRenamePopup.inputValue = ""
      newRenamePopup.open()
    }
    else if (action === "New folder")
    {
      newRenamePopup.context = "New folder"
      newRenamePopup.inputHint = "Folder name"
      newRenamePopup.inputValue = ""      
      newRenamePopup.open()
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
          ftpModel.CreateDirectory(currentDirectory.text + "/" + userInput, true)
        }
        else if (context.startsWith("Rename"))
        {
          ftpModel.Rename(
            currentDirectory.text + "/" + elementName,
            currentDirectory.text + "/" + userInput, true)
        }
        else if (context.startsWith("Delete"))
        {
          var path = currentDirectory.text + "/" + elementName
          elementIsDir ? ftpModel.RemoveDirectory(path, true) :
            ftpModel.RemoveFile(path, true)          
        }
      }
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
        startX: 0; startY: 0
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
      implicitWidth: ListView.view.width
      implicitHeight: 24
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
              folderModel.folder = folderModel.parentFolder
            else
              folderModel.folder = "file:///" + currentDirectory.text +
                (currentDirectory.text.endsWith("\\") ? fileName : ("\\" + fileName))
          }
        }
        onClicked: (mouse) => {
          localListView.currentIndex = index
        }
      }
    }
  }

  function urlToPath(url) {
    var path = url.toString();
    path = path.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
    return decodeURIComponent(path).replace(/\//g, "\\") 
  }

  Component.onCompleted: {}
}