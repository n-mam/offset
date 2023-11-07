import QtQuick

Rectangle {

    property var startIndex: 0

    //radius: 3
    //border.width: 1
    //border.color: borderColor
    color: "transparent"

    signal menuSelectionSignal(var index)

    ListView {
        id: menuList
        clip: true
        spacing: 25
        width: parent.width
        currentIndex: startIndex
        height: parent.height - (parent.height * 0.40)
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
                name: "log.png"
            }
            ListElement {
                name: "settings.png"
            }
        }
        delegate: Item {
            width: menuList.width
            height: 42
            Image {
                width: 32
                height: 32
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