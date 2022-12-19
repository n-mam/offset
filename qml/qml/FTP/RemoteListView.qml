import QtQuick
import QtQuick.Controls

Item {

  implicitWidth: parent.width / 2

  Column {
    spacing: 5
    anchors.fill: parent
    anchors.margins: 5
    anchors.topMargin: 0

    TextField {
      id: currentDirectory
      width: parent.width
      height: parent.height * 0.08
      placeholderText: qsTr("Remote Directory")
      horizontalAlignment: Text.AlignLeft
      verticalAlignment: TextInput.AlignVCenter
      onAccepted: {
        console.log(currentDirectory.text)
        //ListDirectory(currentDirectory.text)
      }
      Component.onCompleted: font.pointSize = font.pointSize - 1.5
    }

    Rectangle {
      width: parent.width
      height: parent.height * 0.87

      radius: 2
      border.width: 1
      border.color: borderColor
      color: Material.background

      ListView {
        anchors.fill: parent
        anchors.margins: 5
        anchors.bottomMargin: 10
        clip: true
        model: ListModel {
                  ListElement {
                    fileName: "x.txt"
                    fileIsDir: true
                  }
                  ListElement {
                    fileName: "y.txt"
                    fileIsDir: false
                  }
                }
        delegate: listItemDelegate
      }
    }

    Text {
      id: status
      color: "white"
      height: parent.height * 0.05
      text: "Total Items : " + 5
    }
  }

  Component {
    id: listItemDelegate
    Rectangle {
      width: ListView.view.width
      height: fileName === "." ? 0 : 26
      // radius: 2
      // border.width: 1
      // border.color: "#123"
      color: Material.background
      Image {
        id: listItemIcon
        x: parent.x + 5
        width: 16; height: 16
        anchors.verticalCenter: parent.verticalCenter
        source: model.fileIsDir ? (fileName !== "." ? "qrc:/folder.png" : "") : "qrc:/file.png"
      }

      Text {
        x: listItemIcon.x + listItemIcon.width + 5
        text: fileName          
        height: parent.height
        color: "white"
        verticalAlignment: Text.AlignVCenter
      }
      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: (containsMouse && model.fileIsDir) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          if (model.fileIsDir) {
            if (fileName == "..")
              folderModel.folder = folderModel.parentFolder
            else
              folderModel.folder = folderModel.folder + "/" + fileName
            currentDirectory.text = urlToPath(folderModel.folder)
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
    console.log(folderModel.folder)
    currentDirectory.text = urlToPath(folderModel.folder)
  }
}