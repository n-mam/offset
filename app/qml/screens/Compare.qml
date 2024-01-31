import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/components"

Rectangle {
    radius: 3
    border.width: 1
    border.color: borderColor
    color: "transparent"

    property var indentSymbol: '&nbsp;'

    SplitView {
        id: compareSplit
        width: parent.width
        orientation: Qt.Horizontal
        height: parent.height * 0.85

        handle: Rectangle {
            id: handleDelegate
            implicitWidth: 1
            implicitHeight: 1
            border.color: borderColor

            containmentMask: Item { // hit area
                x: (handleDelegate.width - width) / 2
                width: 12
                height: compareSplit.height
            }
        }

        CompareFile {
            id: leftCompareFile
            mergeDirection: "A2B"
            onClickedRowChanged: () => {
                lineDiff.updateView(clickedRow)
            }
        }

        CompareFile {
            id: rightCompareFile
            mergeDirection: "B2A"
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
        id: compareControl
        width: parent.width
        anchors.top: lineDiff.bottom
        height: parent.height - compareSplit.height - lineDiff.height
        onIterateChange: (down) => {
            let idx;
            if (down) {
                idx = compareManager.getNextDiffIndex()
            } else {
                idx = compareManager.getPrevDiffIndex()
            }
            leftCompareFile.setCurrentIndex(idx)
            rightCompareFile.setCurrentIndex(idx)
        }
    }
}