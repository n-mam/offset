import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform

ApplicationWindow {
  visible: true
  width: 1280 - (1280 * 0.25)
  height: 720 - (720 * 0.25)
  title: qsTr("Offset")

  property var showlog: false
  property var borderColor: "white" //"#BCDCAA"
  property var appSpacing: 5

  ApplicationMenu {
    id: appMenu
    width: 70
    startIndex: 1
    height: parent.height - (2 * appSpacing)
    anchors.left: parent.left
    anchors.margins: appSpacing
    anchors.verticalCenter: parent.verticalCenter
    onMenuSelectionSignal: (index) => {
      screenContainer.currentIndex = index
    }
  }

  Container {
      id: screenContainer
      focus: true
      currentIndex: appMenu.startIndex
      width: parent.width - appMenu.x - appMenu.width - (2 * appSpacing)
      height: parent.height - (2 * appSpacing)
      anchors.left: appMenu.right
      anchors.verticalCenter: parent.verticalCenter
      contentItem: StackLayout {
          id: layout
          focus: true
          anchors.fill: parent
          anchors.leftMargin: appSpacing
          currentIndex: screenContainer.currentIndex
          Fxc {}
          FTP {}
          Cam {}
          Trace {}
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
