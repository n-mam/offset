import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform

ApplicationWindow {
  width: 590
  height: 620
  visible: true
  title: qsTr("Offset")

  property var showlog: false
  property var borderColor: "white" //"#BCDCAA"
  property var appSpacing: 5

  TabBar {
    id: bar
    width: parent.width
    currentIndex: 1
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
    anchors.margins: 5
    anchors.top: bar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height * 0.90
    currentIndex: bar.currentIndex

    Fxc {}
    FTP {}
    Trace {}
  }

  // Shortcut {
  //   context: Qt.ApplicationShortcut
  //   sequences: ["Ctrl+Q","Ctrl+W"]
  //   onActivated: {
  //     //mainColumn.showlog = !mainColumn.showlog
  //   }
  // }
}
