import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "qrc:/screens"
import "qrc:/components"

ApplicationWindow {
  id: mainWindow
  visible: true
  width: 1430 - (1430 * 0.32)
  height: 860 - (860 * 0.22)
  title: qsTr("Offset")

  property var appSpacing: 5
  property var pointSize: 10
  property var showlog: false
  property var textColor: "white"
  property var textFieldHeight: 34
  property var borderColor: "#727B6C"

  property var charDiffColor: "#be6060" // pink - done
  property var charAddedColor: "#78845C" //light green
  property var charNotRealColor: "#888888" //gray - done
  property var elementDiffFullColor: "#701414" // dark red
  property var elementDiffPartColor: "#5a2626" // light red
  property var elementDiffAddedColor: "#4C5B2B" // dark green

  ApplicationMenu {
    id: appMenu
    width: 48
    startIndex: 3
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
          Compare {}
          Settings {}
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
