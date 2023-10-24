import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "qrc:/screens"
import "qrc:/components"

ApplicationWindow {
  id: mainWindow
  visible: true
  width: 1430 - (1430 * 0.35)
  height: 860 - (860 * 0.30)
  title: qsTr("Offset")

  property var showlog: false
  property var borderColor: "white" //"#BCDCAA"
  property var appSpacing: 5

  ApplicationMenu {
    id: appMenu
    width: 60
    startIndex: 2
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
          Backup {}
          Ftp {}
          Camera {}
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
