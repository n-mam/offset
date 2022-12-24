import QtQuick
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
        ftpModel.InitConnect(host, port, user, password, "ftps");
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
      id: rDelegateRect
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
        id: rfeText
        x: listItemIcon.x + listItemIcon.width + 5
        text: fileName
        height: parent.height
        color: "white"
        verticalAlignment: Text.AlignVCenter
      }

      ContextMenuPopup {
        id: rcontextMenu
        parent: rfeText
        menu: ["Download", "Rename", "Delete", "Refresh", "New folder"]
        onClosed: {
          rfeText.color = "white"
          rDelegateRect.color = Material.background
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
            rDelegateRect.color = "#A3CCAB"
            rfeText.color = "black"
            rcontextMenu.x = mouse.x - rfeText.x
            rcontextMenu.y = mouse.y
            rcontextMenu.open()
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