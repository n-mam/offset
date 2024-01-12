import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/components"

Item {
    id: compareRoot

    property var pointSize: 10

    signal startCompare
    
    SplitView {
        id: compareSplit
        width: parent.width
        height: parent.height * 0.93
        orientation: Qt.Horizontal

        handle: Rectangle {
            id: handleDelegate
            implicitWidth: 2
            implicitHeight: 4
            color: "transparent"

            containmentMask: Item { // hit area
                x: (handleDelegate.width - width) / 2
                width: 48
                height: compareSplit.height
            }
        }

        CompareFile {
            id: leftCompareFile
            pointSize: compareRoot.pointSize
        }

        CompareFile {
            id: rightCompareFile
            pointSize: compareRoot.pointSize
        }

        ScrollBar {
            id: vbar
            height: parent.height
            anchors.right: parent.right
            policy: ScrollBar.AlwaysOff
        }
    }

    Rectangle {
        
        id: compareControls
        // radius: 3
        // border.width: 1
        // border.color: borderColor
        width: parent.width
        color: Material.background
        anchors.bottom: parent.bottom
        anchors.top: compareSplit.bottom
        Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            ButtonX {
                text: "+"
                width: 24
                height: 24
                onButtonXClicked: {
                    compareRoot.pointSize += 1
                }
            }
            Text {
                width: 24
                height: 24
                color: textColor
                text: compareRoot.pointSize
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            ButtonX {
                text: "-"
                width: 24
                height: 24
                onButtonXClicked: {
                    compareRoot.pointSize -= 1
                }
            }
            ButtonX {
                text: "Compare"
                width: 62
                height: 24
                onButtonXClicked: {
                    startCompare();
                }
            }
        }
    }
}