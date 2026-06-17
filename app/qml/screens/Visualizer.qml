import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Vtk 1.0 as Vtk
import "qrc:/components"

Item {
    id: root
    Vtk.VtkQuickItem {
        id: vtkVisualizer
        opacity: 0.7
        anchors.fill: parent
        onPointCloudUpdated: function(percent, points, voxels) {
            progress.visible = stopButton.visible = percent < 100
            progress.value = percent
            numberPoints.text = "Points: " + points
            numberVoxels.text = "Voxels: " + voxels
            // start timer when loading begins
            if (percent === 0) {
                debugOverlay.startTime = Date.now()
                elapsedTimer.start()
            }
            // stop timer when loading finishes
            if (percent >= 100) {
                elapsedTimer.stop()
            }            
        }
        onDistanceUpdated: function(d) {
            distance.text = "Distance: " + d
        }
        function toggle_debug_overlay() {
            debugOverlay.visible = !debugOverlay.visible
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
    RowLayout {
        width: root.width * 0.4
        anchors.topMargin: 20
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        Rectangle {
            id: progress
            height: 18
            width: parent.width * 0.90
            radius: 3
            visible: false
            color: "#404040"
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
                color: "white"
                font.bold: true
                anchors.centerIn: parent
                text: progress.value + "%"
            }
        }
        Rectangle {
            id: stopButton
            width: 18
            height: 18
            visible: false
            color: "transparent"
            Image {
                anchors.fill: parent
                source: "qrc:/stop1.png"
                fillMode: Image.PreserveAspectFit
            }
            MouseArea {
                anchors.fill: parent
                onClicked: vtkVisualizer.stop_load()
            }
        }
    }
    Rectangle {
        id: debugOverlay        
        z: 2000
        radius: 6
        width: 240
        height: 110
        color: "#00000017"
        anchors.margins: 5
        anchors.top: parent.top
        anchors.right: parent.right
        property string line1: "FPS: 0"
        property string line2
        property string line3
        property double startTime: 0
        property int elapsedMs: 0
        Column {
            spacing: 4
            anchors.margins: 8
            anchors.fill: parent
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
            Text {
                id: elapsedTime
                text: "Elapsed: 0"
                color: "white"
                font.pixelSize: 12
                font.family: "monospace"
                width: parent.width
                horizontalAlignment: Text.AlignRight
            }
            Text {
                id: distance
                text: "Distance: 0"
                color: "white"
                font.pixelSize: 12
                font.family: "monospace"
                width: parent.width
                horizontalAlignment: Text.AlignRight
            }            
            Timer {
                id: elapsedTimer
                interval: 100
                repeat: true
                running: false
                onTriggered: {
                    debugOverlay.elapsedMs = Date.now() - debugOverlay.startTime
                    elapsedTime.text = "Elapsed: " + (debugOverlay.elapsedMs / 1000).toFixed(1) + "s"
                }
            }            
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
        }
    }
}