import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Vtk 1.0 as Vtk

Item {
    anchors.fill: parent
    Vtk.MyVtkItem {
        anchors.fill: parent
        anchors.margins: 10
        opacity: 0.7
    }
}