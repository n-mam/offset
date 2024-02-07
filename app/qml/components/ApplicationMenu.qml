import QtQuick

Rectangle {
    //radius: 3
    //border.width: 1
    //border.color: borderColor
    color: "transparent"
    property var startIndex: 0
    signal menuSelectionSignal(var index)

    ListView {
        id: menuList
        clip: true
        spacing: 25
        width: parent.width
        currentIndex: startIndex
        height: parent.height - (parent.height * 0.30)
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
                name: "settings.png"
            }
            ListElement {
                name: "log.png"
            }
        }
        delegate: Item {
            width: menuList.width
            height: 42
            Image {
                width: 28
                height: 28
                source: "qrc:/" + name
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
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