import QtQuick
import QtQuick.Controls

Rectangle {
  // radius: 5
  // border.width: 1
  // border.color: "gray"
  id: delegateRect
  color: "transparent"
  height: 25
  width: ListView.view.width

  Rectangle {
    id: topRow
    // radius: 5
    // border.width: 1
    // border.color: "gray"
    anchors.margins: 5
    color: "transparent"
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height * 0.80
    anchors.verticalCenter: parent.verticalCenter

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
    width: parent.width
    height: parent.height * 0.20
    anchors.top: topRow.bottom
    from: 0
    to: 100
    value: progress
    visible: progress > 0
  }

  Image {
    z: 3
    id: runTransfer
    visible: delegateRect.ListView.view.currentIndex === index
    width: 16; height: 16
    source: "qrc:/run.png"
    anchors.rightMargin: 10
    anchors.right: removeTransfer.left
    anchors.verticalCenter: parent.verticalCenter
    MouseArea {
      hoverEnabled: true
      anchors.fill: parent
      cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: ftpModel.transferModel.ProcessTransfer(index)
    }
  }

  Image {
    z: 3
    id: removeTransfer
    visible: delegateRect.ListView.view.currentIndex === index
    width: 18; height: 18
    source: "qrc:/remove.png"
    anchors.rightMargin: 5
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    MouseArea {
      hoverEnabled: true
      anchors.fill: parent
      cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: () => {
        delegateRect.ListView.view.currentIndex = -1
        ftpModel.transferModel.RemoveTransfer(index)
      }
    }          
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