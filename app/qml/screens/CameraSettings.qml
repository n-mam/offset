import QtQuick
import QtQuick.Controls

Item {

    Text {
        text: "hellow"
        color: "white"
    }

    Component.onCompleted: {
        //console.log("camerasettings completed")
    }
    Component.onDestruction: {
        //console.log("camerasettings destroyed")
    }
}