import QtQuick
import QtQuick.Controls

Rectangle {
    // radius: 3
    // border.width: 1
    // border.color: borderColor
    color: Material.background

    property var startIndex: 0
    signal menuSelectionSignal(var index)

    ListView {
        id: menuList
        clip: true
        spacing: 18
        height: 378
        width: parent.width
        currentIndex: startIndex
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        model: ListModel {
            ListElement {
                name: "fxc.png"
            }
            ListElement {
                name: "ftp.png"
            }
            ListElement {
                name: "camera.png"
            }
            ListElement {
                name: "compare.png"
            }
            ListElement {
                name: "house-plan.png"
            }
            ListElement {
                name: "log.png"
            }
        }
        delegate: Item {
            height: 42
            width: menuList.width
            Image {
                width: 28
                height: 28
                source: "qrc:/" + name
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: menuList.currentIndex = index
            }
        }
        highlight: Rectangle {
            radius: 3
            color: "steelblue"
        }
        onCurrentIndexChanged: {
            menuSelectionSignal(currentIndex)
        }
    }
}