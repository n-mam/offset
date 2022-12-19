import QtQuick
import QtQuick.Controls

Item {

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

}