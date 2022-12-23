import QtQuick
import QtQuick.Controls

Item {

  Rectangle {
    radius: 5
    border.width: 1
    border.color: borderColor
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height * 0.85
    color: Material.background

    ListModel {
      id: traceModel
      ListElement {line: ""}
    }

    ListView {
      id: traceView
      clip: true
      anchors.fill: parent
      anchors.margins: 5
      model: traceModel
      delegate: Item {
        width: ListView.view.width;
        height: 17
        Label { 
          text: line
          Component.onCompleted: font.pointSize = font.pointSize - 2
        }
      }
      Connections {
        target: logger
        function onAddLogLine(severity, log) {
          if (severity === 3) {
            statusText.text = log
          } else {
            traceModel.append({line: log})
          }
        }
      }
    }

    Rectangle {
      id: logActions
      // radius: 5
      // border.width: 1
      // border.color: borderColor
      anchors.top: traceView.bottom
      anchors.margins: 5
      color: Material.background
      anchors.horizontalCenter: parent.horizontalCenter
      width: 75 + 75 + (3 * appSpacing)
      height: parent.height * 0.10
      Button {
        id: clearButton
        width: 75
        text: "CLEAR"
        enabled: (diskListModel.transfer === 0)
        height: parent.height * 0.85
        anchors.left: parent.left
        anchors.margins: appSpacing
        anchors.verticalCenter: parent.verticalCenter
        onClicked: traceModel.clear()
      }
      Button {
        id: savebutton
        width: 75
        text: "SAVE"
        enabled: (diskListModel.transfer !== 0)
        height: parent.height * 0.85
        anchors.left: clearButton.right
        anchors.margins: appSpacing
        anchors.verticalCenter: parent.verticalCenter
        onClicked: {}
      }
    }
  }
}