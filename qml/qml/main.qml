import QtQuick
import QtQuick.Controls
import Qt.labs.platform

ApplicationWindow {
  width: 500
  height: 600
  visible: true
  title: qsTr("Offset")

  property var borderColor: "#BCDCAA"

  Column {
    id: mainColumn
    spacing: 5
    topPadding: 10
    width: parent.width
    height: parent.height

    property var showlog: false

    Rectangle {
      id: log
      radius: 5
      border.width: 1
      border.color: borderColor
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 10
      height: mainColumn.showlog ? (mainColumn.height * 0.25) : 0
      color: Material.background
      Flickable {
        id: flickable
        clip: true
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        TextArea.flickable: TextArea {
          id: logText
          color: "white"
          visible: mainColumn.showlog
          anchors.fill: parent
          anchors.leftMargin: 5
          background: null
          font.pointSize: 9
          Connections {
            target: logger
            function onAddLogLine(log) {
              logText.append(log)
              logText.cursorPosition = logText.length - log.length
            }
          }
        }
        ScrollBar.vertical: ScrollBar {}
      }
    }

    Fxc {
      anchors.margins: 10
      anchors.left: parent.left
      anchors.right: parent.right
      height: mainColumn.height * (log.height ? 0.75 : 1.00)
    }
  }

  Shortcut {
    context: Qt.ApplicationShortcut
    sequences: ["Ctrl+Q","Ctrl+W"]
    onActivated: {
      mainColumn.showlog = !mainColumn.showlog
      mainColumn.forceLayout();
    }
  }
}
