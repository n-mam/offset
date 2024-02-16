import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    property var baseItem;
    Image {
        z: 100
        anchors.margins: 10
        anchors.top: parent.top
        anchors.right: parent.right
        enabled: stackview.depth > 1
        source: stackview.depth > 1 ? "qrc:/back.png" : ""
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            onClicked: stackview.pop()
            cursorShape: Qt.PointingHandCursor
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
    Component.onCompleted: {}
}