import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import "qrc:/screens"
import "qrc:/components"

ApplicationWindow {
    id: mainWindow
    visible: true
    title: qsTr("Offset")
    height: 860 - (860 * 0.22)
    width: 1430 - (1430 * 0.30)

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

    Row {
        spacing: appSpacing
        anchors.fill: parent
        anchors.margins: appSpacing
        ApplicationMenu {
            id: appMenu
            width: 40
            startIndex: 3
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            onMenuSelectionSignal: (index) => {
                screenContainer.currentIndex = index
            }
        }
        Container {
            id: screenContainer
            focus: true
            height: parent.height
            currentIndex: appMenu.startIndex
            width: parent.width - (appSpacing + appMenu.width + appSpacing)
            contentItem: StackLayout {
                id: layout
                focus: true
                anchors.fill: parent
                currentIndex: screenContainer.currentIndex
                Backup {}
                Ftp {}
                Camera {}
                Compare {}
                Settings {}
                Trace {}
            }
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
