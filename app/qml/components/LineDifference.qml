import QtQuick
import QtQml.Models
import QtQuick.Controls
import "qrc:/delegates"

Item {
    property var modelTop
    property var modelBottom
    Column {
        spacing: 2
        anchors.fill: parent
        Rectangle {
            radius: 3
            border.width: 1
            border.color: borderColor
            width: parent.width
            height: parent.height / 2
            color: Material.background
            ListView {
                id: leftListView
                clip: true
                model: modelTop
                interactive: false
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                delegate: CompareLineDelegate {
                    width: ListView.view.width
                    height: ListView.view.height
                }
            }
        }
        Rectangle {
            radius: 3
            border.width: 1
            border.color: borderColor
            width: parent.width
            height: parent.height / 2
            color: Material.background
            ListView {
                id: rightListView
                clip: true
                model: modelBottom
                interactive: false
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                delegate: CompareLineDelegate {
                    width: ListView.view.width
                    height: ListView.view.height
                }
            }
        }
    }

    function updateView(row) {
        console.log(updateView, row)
        leftListView.positionViewAtIndex(row - 1, ListView.Center)
        rightListView.positionViewAtIndex(row - 1, ListView.Center)
    }
}
