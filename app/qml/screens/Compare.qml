import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/components"

Item {
    id: compareRoot
    Column{
        spacing: 4
        anchors.fill: parent
        SplitView {
            id: compareSplit
            width: parent.width
            height: parent.height * 0.83
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
                onClickedRowChanged: () => {
                    lineDiff.updateView(clickedRow)
                }
            }

            CompareFile {
                id: rightCompareFile
                onClickedRowChanged: () => {
                    lineDiff.updateView(clickedRow)
                }
            }

            ScrollBar {
                id: vbar
                height: parent.height
                anchors.right: parent.right
                policy: ScrollBar.AlwaysOff
            }
        }

        LineDifference {
            id: lineDiff
            width: parent.width
            height: parent.height * 0.11
            modelTop: leftCompareFile.getModel()
            modelBottom: rightCompareFile.getModel()
        }

        Rectangle {
            id: compareControls
            // radius: 3
            // border.width: 1
            // border.color: borderColor
            width: parent.width
            color: Material.background
            height: parent.height - compareSplit.height - lineDiff.height
            Row {
                spacing: 4
                ButtonX {
                    text: "-"
                    width: 24
                    height: 26
                    onButtonXClicked: pointSize -= 1
                }
                TextField {
                    width: 46
                    height: 26
                    color: textColor
                    font.pointSize: 8
                    text: pointSize.toString()
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    onAccepted: pointSize = parseInt(text, 10)
                }
                ButtonX {
                    text: "+"
                    width: 24
                    height: 26
                    onButtonXClicked: pointSize += 1
                    
                }
                ButtonX {
                    text: "Compare"
                    width: 62
                    height: 26
                    onButtonXClicked: compareManager.compare()
                }
            }
        }
    
    }
}