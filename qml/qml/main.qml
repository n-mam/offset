import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform

ApplicationWindow {
  width: 560
  height: 600
  visible: true
  title: qsTr("Offset")

  property var showlog: false
  property var borderColor: "#BCDCAA"
  property var appSpacing: 5

  TabBar {
    id: bar
    width: parent.width
    TabButton {
      text: qsTr("FXC")
    }
    TabButton {
      text: qsTr("FTP")
    }
    TabButton {
      text: qsTr("LOG")
    }
  }

  StackLayout {
    width: parent.width
    height: parent.height * 0.95
    currentIndex: bar.currentIndex
    anchors.margins: 5   
    anchors.top: bar.bottom
    anchors.left: parent.left
    anchors.right: parent.right

    Fxc {
      id: fxc
      height: parent.height
    }
    FTP {
      id: ftp
      height: parent.height
    }
    Trace {
      id: log
      height: parent.height
    }
  }

  // Shortcut {
  //   context: Qt.ApplicationShortcut
  //   sequences: ["Ctrl+Q","Ctrl+W"]
  //   onActivated: {
  //     //mainColumn.showlog = !mainColumn.showlog
  //   }
  // }
}
