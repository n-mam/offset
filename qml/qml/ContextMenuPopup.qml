import QtQuick
import QtQuick.Controls

Popup {
  required property var menu;
  contentItem: Item {
    anchors.fill: parent
    Rectangle {
      radius: 3
      border.width: 1
      border.color: "white"
      color: Qt.darker(Material.background)
      width: 100
      height: 130
      ListView {
        spacing: 10
        anchors.margins: 5
        anchors.fill: parent
        model: ListModel { id: menuModel }
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
        Component.onCompleted: {
          for (var e of menu)
            menuModel.append({"name": e})
        }
      }
    }
  }
  onOpened: {
  }
  onClosed: {
  }
}