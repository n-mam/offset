import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "qrc:/screens"
import "qrc:/components"

ApplicationWindow {
  id: mainWindow
  visible: true
  width: 1430 - (1430 * 0.30)
  height: 860 - (860 * 0.22)
  title: qsTr("Offset")

  property var appSpacing: 5
  property var pointSize: 10
  property var showlog: false
  property var textColor: "white"
  property var textFieldHeight: 34
  property var borderColor: "#404040"

  property var charDiffColor: "#be6060" // pink - done
  property var charAddedColor: "#78845C" //light green
  property var charNotRealColor: "#aaaaaa" //gray - done
  property var elementDiffFullColor: "#701414" // dark red
  property var elementDiffPartColor: "#6f3737" // light red
  property var elementDiffAddedColor: "#4C5B2B" // dark green

  ApplicationMenu {
    id: appMenu
    width: 40
    startIndex: 3
    anchors.left: parent.left
    anchors.margins: appSpacing
    height: parent.height - (2 * appSpacing)
    anchors.verticalCenter: parent.verticalCenter
    onMenuSelectionSignal: (index) => {
      screenContainer.currentIndex = index
    }
  }

  Container {
      id: screenContainer
      focus: true
      anchors.left: appMenu.right
      currentIndex: appMenu.startIndex
      height: parent.height - (2 * appSpacing)
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - appMenu.x - appMenu.width - (2 * appSpacing)
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
