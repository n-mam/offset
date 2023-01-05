import QtQuick
import QtQuick.Controls

Rectangle {
  // radius: 5
  // border.width: 1
  // border.color: "gray"
  id: delegateRect
  color: "transparent"
  height: 23
  width: ListView.view.width

  Rectangle {
    id: topRow
    // radius: 5
    // border.width: 1
    // border.color: "gray"
    width: parent.width
    height: parent.height * 0.80
    color: "transparent"

    Text {
      id: localText
      width: parent.width * 0.50
      color: delegateRect.ListView.isCurrentItem ? "black" : "white"
      text: local
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: arrow
      width: parent.width * 0.05
      color: delegateRect.ListView.isCurrentItem ? "black" : "white"
      text: (direction === 2) ? "-->" : "<--"
      x: localText.x + localText.width + 10
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: remoteText
      width: parent.width * 0.45
      color: delegateRect.ListView.isCurrentItem ? "black" : "white"
      text: remote
      elide: Text.ElideRight
      x: arrow.x + arrow.width + 10
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  ProgressBar {
    width: parent.width * 0.70
    height: parent.height * 0.20
    anchors.top: topRow.bottom
    from: 0
    to: 100
    value: progress
    visible: progress > 0
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      delegateRect.ListView.view.currentIndex = index
    }
  }

  Component.onCompleted: {
  }
}