import QtQuick
import QtQml.Models
import QtQuick.Shapes
import QtQuick.Controls
import "qrc:/delegates"

Rectangle {
    radius: 0
    border.width: 1
    border.color: borderColor
    color: Material.background
    property var modelA
    property var modelB

    ListView {
        id: leftListView
        clip: true
        model: modelA
        interactive: false
        anchors.leftMargin: 10
        anchors.rightMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        height: (parent.height / 2)
        delegate: CompareLineDelegate {
            innerMargin: 2
            width: ListView.view.width
            height: ListView.view.height
            property var mergeDirection: "A2B"
        }
    }
    Shape {
        id: divider
        height: 1
        width: parent.width
        anchors.centerIn: parent
        ShapePath {
            startX: 0; startY: 1
            strokeColor: borderColor
            joinStyle: ShapePath.RoundJoin
            strokeStyle: ShapePath.SolidLine
            PathLine {x: divider.width; y: 1}
        }
    }
    ListView {
        id: rightListView
        clip: true
        model: modelB
        interactive: false
        anchors.leftMargin: 10
        anchors.rightMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        height: (parent.height / 2)
        anchors.bottom: parent.bottom
        delegate: CompareLineDelegate {
            innerMargin: 2
            width: ListView.view.width
            height: ListView.view.height
            property var mergeDirection: "B2A"
        }
    }

    function updateView(row) {
        leftListView.positionViewAtIndex(row - 1, ListView.Center)
        rightListView.positionViewAtIndex(row - 1, ListView.Center)
    }
}
