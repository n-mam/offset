import QtQuick
import QtQml.Models
import QtQuick.Shapes
import QtQuick.Controls
import "qrc:/components"

Rectangle {
    radius: 3
    border.width: 1
    border.color: borderColor
    color: "transparent"

    property var indentSymbol: '&nbsp;'

    Row {
        id: splitOverviewRow
        width: parent.width
        height: parent.height * 0.85
        SplitView {
            id: compareSplit
            height: parent.height
            orientation: Qt.Horizontal
            width: parent.width - overview.width - divider.width

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
        Shape {
            id: divider
            width: 1
            height: parent.height
            ShapePath {
                startX: 0; startY: 1
                strokeColor: borderColor
                joinStyle: ShapePath.RoundJoin
                strokeStyle: ShapePath.SolidLine
                PathLine { x: 0; y: divider.height }
            }
        }
        Overview {
            id: overview
            width: 45
            height: parent.height
            modelA: leftCompareFile.getModel()
            modelB: rightCompareFile.getModel()
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

    LineDifference {
        id: lineDiff
        width: parent.width
        height: parent.height * 0.08
        anchors.top: splitOverviewRow.bottom
        modelA: leftCompareFile.getModel()
        modelB: rightCompareFile.getModel()
    }

    CompareControls {
        id: compareControl
        width: parent.width
        anchors.top: lineDiff.bottom
        height: parent.height - splitOverviewRow.height - lineDiff.height
        onComparisonDone: () => {
            overview.modelA = leftCompareFile.getModel()
            overview.modelB = rightCompareFile.getModel()
            overview.update();
        }
    }
}