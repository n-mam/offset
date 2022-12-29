import QtQuick
import QtQuick.Controls

Rectangle {
  // radius: 5
  // border.width: 1
  // border.color: "gray"
  color: "transparent"
  height: 35
  width: ListView.view.width

  Column {
    spacing: 2
    anchors.fill: parent
    
    Rectangle {
      // radius: 5
      // border.width: 1
      // border.color: "gray"
      color: "transparent"
      width: parent.width
      height: parent.height * 0.50
      Text {
        id: localText
        width: parent.width * 0.40
        color: "white"
        text: local
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: arrow
        width: parent.width * 0.05
        color: "white"
        text: (direction === 2) ? "-->" : "<--"
        elide: Text.ElideRight
        x: (parent.width * 0.40) + 10
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: remoteText
        width: parent.width * 0.40
        color: "white"
        text: remote
        elide: Text.ElideRight
        x: (parent.width * 0.40) + 10 + (parent.width * 0.10) + 2
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    ProgressBar {
      width: parent.width * 0.65
      height: parent.height * 0.40
      from: 0
      to: 100
      value: 50
    }
  }
  Component.onCompleted: {
  }
}