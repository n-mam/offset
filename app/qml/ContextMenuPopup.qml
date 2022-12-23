import QtQuick
import QtQuick.Controls

Popup {
  x: parent.width / 2
  y: parent.height / 2
  contentItem: Item {
    anchors.fill: parent
    Rectangle {
      radius: 5
      border.width: 1
      border.color: "white"
      color: Qt.darker(Material.background)
      width: 100
      height: 130
      ListView {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 5
        model: ListModel {
          ListElement {
            name: "Download"
          }
          ListElement {
            name: "Rename"
          }
          ListElement {
            name: "Delete"
          }                        
          ListElement {
            name: "Refresh"
          }
          ListElement {
            name: "New folder"
          }  
        }
        delegate: Text {
          text: name
          color: "white"
          anchors.horizontalCenter: parent.horizontalCenter
          MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            onEntered: parent.color = "#9AEBA3"
            onExited: parent.color = "white"
          }
        }
      }      
    }
  }
  onOpened: {

  }
}