import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Vtk 1.0 as Vtk
import "qrc:/components"

Item {
    //anchors.fill: parent
    Vtk.VtkQuickItem {
        id: vtkVisualizer
        anchors.fill: parent
        opacity: 0.7
    }
    VtkToolBox {
        id: vtkTools
        z: 1000
        anchors.margins: 8
        visualizer: vtkVisualizer
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}