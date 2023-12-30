import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/components"

Item {

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

        DiffView {
            id: leftDiffView
        }

        DiffView {
            id: rightDiffView
        }
    }

    Rectangle {
        id: compareControls
        width: parent.width
        height: parent.height * 0.7
        anchors.top: compareSplit.bottom
        color: Material.background
        Row {
            spacing: 4
            Button {
                text: "+"
            }
            Button {
                text: "-"
            }
        }
    }
}