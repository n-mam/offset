import QtQuick
import QtQuick.Controls

Item {
    id: cldRoot
    Row {
        spacing: 1
        width: parent.width
        height: parent.height
        Text{
            text: "<span>" + lineNumber + 
                        lineIndentSymbol.repeat(
                            (cldRoot.ListView.view.model.rowCount().toString().length + 1) - 
                                lineNumber.toString().length) + 
                  "</span>"
            color: "#A4A4A4" //6E7681"
        }
        Text {
            color: textColor
            text: "<span>" + lineText + "</span>"
        }
    }
}