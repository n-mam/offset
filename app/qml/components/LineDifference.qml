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
        anchors.rightMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        height: (parent.height / 2)
        delegate: CompareLineDelegate {
            innerMargin: 1
            width: ListView.view.width
            height: ListView.view.height
        }
    }
    Rectangle {
        id: spacer
        height: 1
        width: parent.width
        anchors.centerIn: parent
        color: Material.background
        Shape {
            anchors.fill: spacer
            anchors.centerIn: spacer
            ShapePath {
                startX: 0; startY: 1
                strokeColor: borderColor
                strokeStyle: ShapePath.SolidLine
                PathLine {x: spacer.width; y: 1}
            }
        }
    }
    ListView {
        id: rightListView
        clip: true
        model: modelB
        interactive: false
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        height: (parent.height / 2)
        anchors.bottom: parent.bottom
        delegate: CompareLineDelegate {
            innerMargin: 1
            width: ListView.view.width
            height: ListView.view.height
        }
    }

    function updateView(row) {
        leftListView.positionViewAtIndex(row - 1, ListView.Center)
        rightListView.positionViewAtIndex(row - 1, ListView.Center)
    }
}
