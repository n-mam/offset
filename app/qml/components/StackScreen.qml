import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {

    property var baseItem;

    Image {
        z: 100
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        source: stackview.depth > 1 ? "qrc:/back.png" : ""
        enabled: stackview.depth > 1
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                stackview.pop()
            }
            onContainsMouseChanged: parent.scale = 1 + (containsMouse ? 0.2 : 0)
        }
    }

    StackView {
        id: stackview
        anchors.fill: parent
        initialItem: baseItem
    }

    function pushComponent(qml, options) {
        stackview.push(qml, options)
    }

    Component.onCompleted: {

    }
}