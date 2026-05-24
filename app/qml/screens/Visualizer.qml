import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Vtk 1.0 as Vtk
import "qrc:/components"

Item {
    Vtk.VtkQuickItem {
        id: vtkVisualizer
        opacity: 0.7
        anchors.fill: parent
        onPointCloudUpdated: function(percent, points, voxels) {
            progress.visible = percent < 100
            progress.value = percent
            numberPoints.text = "Points: " + points
            numberVoxels.text = "Voxels: " + voxels
        }
    }
    VtkToolBox {
        id: vtkTools
        z: 1000
        anchors.margins: 8
        visualizer: vtkVisualizer
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        id: progress
        height: 18
        radius: 3
        visible: false
        color: "#404040"
        anchors.topMargin: 20
        anchors.top: parent.top
        width: parent.width * 0.4
        anchors.horizontalCenter: parent.horizontalCenter
        property int value: 0
        Rectangle {
            id: bar
            height: parent.height
            width: parent.width * (progress.value / 100)
            radius: parent.radius
            color: "#3daee9"
            Behavior on width {
                NumberAnimation {
                    duration: 200
                }
            }
        }
        Text {
            id: percent
            anchors.centerIn: parent
            color: "white"
            font.bold: true
            text: progress.value + "%"
        }
    }
    Rectangle {
        id: debugOverlay
        width: 240
        height: 110
        radius: 6
        color: "#00000017"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 5
        z: 2000
        property string line1: "FPS: 0"
        property string line2
        property string line3
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            Text {
                id: numberPoints
                text: "Points: 0"
                color: "white"
                font.pixelSize: 12
                font.family: "monospace"
                width: parent.width
                horizontalAlignment: Text.AlignRight
            }
            Text {
                id: numberVoxels
                text: "Voxels: 0"
                color: "white"
                font.pixelSize: 12
                font.family: "monospace"
                width: parent.width
                horizontalAlignment: Text.AlignRight
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
        }
    }
    // vtkVisualizer.stop_load()
}