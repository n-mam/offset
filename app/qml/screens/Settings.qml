import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    width: 800
    height: 600
    focus: true
    Keys.enabled: true

    // Camera
    property real zoom: 1.0
    property real pixelsPerFoot: 50
    property real offsetX: width / 2
    property real offsetY: height / 2

    // Walls stored IN FEET
    property var walls: []

    // Drawing state
    property bool drawingWall: false
    property real startXFeet: 0
    property real startYFeet: 0
    property real currentXFeet: 0
    property real currentYFeet: 0

    property int selectedWall: -1
    property real pickToleranceFeet: 0.15   // ~2 inches

    property var undoStack: []
    property int maxUndoSteps: 50

    function screenToFeet(x, y) {
        const px = (x - offsetX) / zoom
        const py = (y - offsetY) / zoom
        return {
            x: px / pixelsPerFoot,
            y: py / pixelsPerFoot
        }
    }

    function distancePointToSegment(px, py, x1, y1, x2, y2) {
        const vx = x2 - x1
        const vy = y2 - y1
        const wx = px - x1
        const wy = py - y1

        const c1 = vx * wx + vy * wy
        if (c1 <= 0)
            return Math.hypot(px - x1, py - y1)

        const c2 = vx * vx + vy * vy
        if (c2 <= c1)
            return Math.hypot(px - x2, py - y2)

        const b = c1 / c2
        const bx = x1 + b * vx
        const by = y1 + b * vy
        return Math.hypot(px - bx, py - by)
    }

    function pushUndoState() {
        // Deep copy walls
        undoStack.push(JSON.parse(JSON.stringify(walls)))
        if (undoStack.length > maxUndoSteps)
            undoStack.shift()
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.save()
            ctx.translate(offsetX, offsetY)
            ctx.scale(zoom, zoom)
            // Grid (1 ft)
            for (let i = -200; i <= 200; i++) {
                const major = (i % 5 === 0)
                ctx.strokeStyle = major ? "#505050" : "#3a3a3a"
                ctx.lineWidth = major ? 2 / zoom : 1 / zoom
                ctx.beginPath()
                ctx.moveTo(i * pixelsPerFoot, -10000)
                ctx.lineTo(i * pixelsPerFoot, 10000)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(-10000, i * pixelsPerFoot)
                ctx.lineTo(10000, i * pixelsPerFoot)
                ctx.stroke()
            }

            // Walls
            ctx.strokeStyle = "#ffffff"
            ctx.lineWidth = 3 / zoom
            walls.forEach((w, i) => {
                ctx.strokeStyle = (i === selectedWall) ? "#ff5555" : "#ffffff"
                ctx.lineWidth = (i === selectedWall ? 5 : 3) / zoom
                ctx.beginPath()
                ctx.moveTo(w.x1 * pixelsPerFoot, w.y1 * pixelsPerFoot)
                ctx.lineTo(w.x2 * pixelsPerFoot, w.y2 * pixelsPerFoot)
                ctx.stroke()
            })

            // Preview wall + length label
            if (drawingWall) {
                const x1 = startXFeet * pixelsPerFoot
                const y1 = startYFeet * pixelsPerFoot
                const x2 = currentXFeet * pixelsPerFoot
                const y2 = currentYFeet * pixelsPerFoot

                ctx.strokeStyle = "#00ff88"
                ctx.lineWidth = 2 / zoom
                ctx.setLineDash([6 / zoom, 6 / zoom])

                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.stroke()
                ctx.setLineDash([])

                const dx = currentXFeet - startXFeet
                const dy = currentYFeet - startYFeet
                const lengthFeet = Math.sqrt(dx * dx + dy * dy)

                const mx = (x1 + x2) / 2
                const my = (y1 + y2) / 2

                const label = lengthFeet.toFixed(2) + " ft"
                ctx.font = `${12 / zoom}px sans-serif`
                const tw = ctx.measureText(label).width
                const pad = 4 / zoom

                ctx.fillStyle = "rgba(0,0,0,0.7)"
                ctx.fillRect(mx - tw / 2 - pad, my - 12 / zoom,
                             tw + pad * 2, 16 / zoom)

                ctx.fillStyle = "#00ff88"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(label, mx, my)
            }
            ctx.restore()
        }
    }

    onZoomChanged: canvas.requestPaint()
    onOffsetXChanged: canvas.requestPaint()
    onOffsetYChanged: canvas.requestPaint()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        property real lastX
        property real lastY

        cursorShape: (pressedButtons & Qt.RightButton)
            ? Qt.ClosedHandCursor
            : Qt.ArrowCursor

        onPressed: (mouse) => {
            root.forceActiveFocus()
            if (mouse.button === Qt.LeftButton) {
                const p = screenToFeet(mouse.x, mouse.y)
                let hit = -1
                let best = pickToleranceFeet
                for (let i = 0; i < walls.length; i++) {
                    const w = walls[i]
                    const d = distancePointToSegment(
                        p.x, p.y,
                        w.x1, w.y1,
                        w.x2, w.y2
                    )
                    if (d < best) {
                        best = d
                        hit = i
                    }
                }
                if (hit !== -1) {
                    // Select existing wall
                    selectedWall = hit
                    drawingWall = false
                } else {
                    // Start drawing a new wall
                    selectedWall = -1
                    startXFeet = p.x
                    startYFeet = p.y
                    currentXFeet = p.x
                    currentYFeet = p.y
                    drawingWall = true
                }
                canvas.requestPaint()
            } else if (mouse.button === Qt.RightButton) {
                lastX = mouse.x
                lastY = mouse.y
            }
        }

        onPositionChanged: (mouse) => {
            if (drawingWall && (mouse.buttons & Qt.LeftButton)) {
                const p = screenToFeet(mouse.x, mouse.y)
                currentXFeet = p.x
                currentYFeet = p.y
                canvas.requestPaint()
            } else if (mouse.buttons & Qt.RightButton) {
                offsetX += mouse.x - lastX
                offsetY += mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y
            }
        }

        onReleased: (mouse) => {
            if (drawingWall && mouse.button === Qt.LeftButton) {
                pushUndoState()
                walls.push({
                    x1: startXFeet,
                    y1: startYFeet,
                    x2: currentXFeet,
                    y2: currentYFeet
                })
                drawingWall = false
                canvas.requestPaint()
            }
        }

        onWheel: (wheel) => {
            const factor = wheel.angleDelta.y > 0 ? 1.1 : 0.9
            zoom = Math.max(0.2, Math.min(5, zoom * factor))
        }
    }

    Keys.onDeletePressed: {
        if (selectedWall !== -1) {
            pushUndoState()
            walls.splice(selectedWall, 1)
            selectedWall = -1
            canvas.requestPaint()
        }
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) {
            if (undoStack.length > 0) {
                walls = undoStack.pop()
                selectedWall = -1
                canvas.requestPaint()
            }
            event.accepted = true
        }
    }
}
