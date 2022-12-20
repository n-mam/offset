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

    Flickable {
      id: flickable
      clip: true
      anchors.fill: parent
      flickableDirection: Flickable.VerticalFlick
      TextArea.flickable: TextArea {
        id: logText
        color: "white"
        anchors.fill: parent
        anchors.leftMargin: 5
        background: null
        Component.onCompleted: font.pointSize = font.pointSize - 3
        Connections {
          target: logger
          function onAddLogLine(severity, log) {
            if (severity === 3) {
              statusText.text = log
            } else {
              logText.append(log)
              logText.cursorPosition = logText.length - log.length
            }
          }
        }
      }
      ScrollBar.vertical: ScrollBar {}
    }

    Rectangle {
      id: logActions
      // radius: 5
      // border.width: 1
      // border.color: borderColor
      anchors.top: flickable.bottom
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
        onClicked: {
          
        }
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
        onClicked: {
          
        }
      }
    }

  }
}