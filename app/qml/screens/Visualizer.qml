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
        onPointCloudProgress: function(completed) {
            progress.visible = completed < 100
            progress.value = completed
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
    // vtkVisualizer.stop_load()
}