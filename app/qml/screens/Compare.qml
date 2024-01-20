import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/components"

Rectangle {
    radius: 3
    border.width: 1
    border.color: borderColor
    color: "transparent"

    SplitView {
        id: compareSplit
        width: parent.width
        height: parent.height * 0.84
        orientation: Qt.Horizontal

        handle: Rectangle {
            id: handleDelegate
            implicitWidth: 2
            implicitHeight: 4
            border.color: borderColor

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
        height: parent.height * 0.08
        anchors.top: compareSplit.bottom
        modelA: leftCompareFile.getModel()
        modelB: rightCompareFile.getModel()
    }

    CompareControls {
        id: compareControlId
        width: parent.width
        anchors.top: lineDiff.bottom
        height: parent.height - compareSplit.height - lineDiff.height
    }
}