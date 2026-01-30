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
    property real wallThicknessFeet: 0.5   // 6 inches
    property var wallPattern: null

    // Colors (centralized)
    property string wallFillColor: "#dcd0aa" // sand color
    property string hatchStrokeColor: "rgba(140,110,70,0.6)"
    property string wallOutlineColor: "rgba(120,95,60,0.6)"

    // Drawing state
    property bool drawingWall: false
    property real startXFeet: 0
    property real startYFeet: 0
    property real currentXFeet: 0
    property real currentYFeet: 0

    property int selectedWall: -1
    property real pickTolerancePixels: 5   // feels good: 6–10 px

    property var undoStack: []
    property int maxUndoSteps: 50

    function screenToFeet(x, y) {
        const px = (x - offsetX) / zoom
        const py = (y - offsetY) / zoom
        return { x: px / pixelsPerFoot, y: py / pixelsPerFoot }
    }

    function polygonPath(ctx, corners) {
        ctx.beginPath()
        ctx.moveTo(corners[0].x, corners[0].y)
        for (let i = 1; i < corners.length; i++)
            ctx.lineTo(corners[i].x, corners[i].y)
        ctx.closePath()
    }

    function drawWallRect(ctx, w) {
        const dx = w.x2 - w.x1
        const dy = w.y2 - w.y1
        const len = Math.hypot(dx, dy)
        if (len === 0) return

        const halfThicknessPx = (wallThicknessFeet / 2) * pixelsPerFoot
        const pxLen = len * pixelsPerFoot
        const x1 = w.x1 * pixelsPerFoot
        const y1 = w.y1 * pixelsPerFoot

        const tx = dx / len
        const ty = dy / len
        const nx = -ty
        const ny = tx

        const corners = [
            { x: x1 + nx * halfThicknessPx, y: y1 + ny * halfThicknessPx },
            { x: x1 + tx * pxLen + nx * halfThicknessPx, y: y1 + ty * pxLen + ny * halfThicknessPx },
            { x: x1 + tx * pxLen - nx * halfThicknessPx, y: y1 + ty * pxLen - ny * halfThicknessPx },
            { x: x1 - nx * halfThicknessPx, y: y1 - ny * halfThicknessPx }
        ]

        polygonPath(ctx, corners)
        ctx.fillStyle = wallFillColor
        ctx.fill()

        ctx.save()
        polygonPath(ctx, corners)
        ctx.clip()

        const spacing = 6 / zoom
        const hatchAngle = Math.PI / 4
        const cosA = Math.cos(hatchAngle)
        const sinA = Math.sin(hatchAngle)
        const xs = corners.map(c => c.x)
        const ys = corners.map(c => c.y)
        const minX = Math.min(...xs)
        const maxX = Math.max(...xs)
        const minY = Math.min(...ys)
        const maxY = Math.max(...ys)
        const diagLen = Math.hypot(maxX - minX, maxY - minY)

        ctx.strokeStyle = hatchStrokeColor
        ctx.lineWidth = 1 / zoom
        for (let i = -diagLen; i < diagLen * 2; i += spacing) {
            const offsetX = i * (-sinA)
            const offsetY = i * cosA
            const startX = minX + offsetX
            const startY = minY + offsetY
            const endX = startX + diagLen * cosA
            const endY = startY + diagLen * sinA
            ctx.beginPath()
            ctx.moveTo(startX, startY)
            ctx.lineTo(endX, endY)
            ctx.stroke()
        }
        ctx.restore()

        polygonPath(ctx, corners)
        ctx.strokeStyle = wallOutlineColor
        ctx.lineWidth = 1 / zoom
        ctx.stroke()
    }

    function distanceToPoint(px, py, x, y) {
        return Math.hypot(px - x, py - y)
    }

    function distancePointToSegment(px, py, x1, y1, x2, y2) {
        const vx = x2 - x1
        const vy = y2 - y1
        const wx = px - x1
        const wy = py - y1
        const c1 = vx * wx + vy * wy
        if (c1 <= 0) return Math.hypot(px - x1, py - y1)
        const c2 = vx * vx + vy * vy
        if (c2 <= c1) return Math.hypot(px - x2, py - y2)
        const b = c1 / c2
        const bx = x1 + b * vx
        const by = y1 + b * vy
        return Math.hypot(px - bx, py - by)
    }

    function pushUndoState() {
        if (undoStack.length >= maxUndoSteps)
            undoStack.shift()
        undoStack.push(walls.map(w => Object.assign({}, w)))
    }

    Rectangle { anchors.fill: parent; color: "#1e1e1e" }

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

            // Grid
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
            walls.forEach((w, i) => {
                drawWallRect(ctx, w)

                if (i === selectedWall) {
                    const dx = w.x2 - w.x1
                    const dy = w.y2 - w.y1
                    const len = Math.hypot(dx, dy)
                    if (len === 0) return
                    const halfThicknessPx = (wallThicknessFeet / 2) * pixelsPerFoot
                    const pxLen = len * pixelsPerFoot
                    const x1 = w.x1 * pixelsPerFoot
                    const y1 = w.y1 * pixelsPerFoot
                    const tx = dx / len
                    const ty = dy / len
                    const nx = -ty
                    const ny = tx
                    const corners = [
                        { x: x1 + nx * halfThicknessPx, y: y1 + ny * halfThicknessPx },
                        { x: x1 + tx * pxLen + nx * halfThicknessPx, y: y1 + ty * pxLen + ny * halfThicknessPx },
                        { x: x1 + tx * pxLen - nx * halfThicknessPx, y: y1 + ty * pxLen - ny * halfThicknessPx },
                        { x: x1 - nx * halfThicknessPx, y: y1 - ny * halfThicknessPx }
                    ]
                    polygonPath(ctx, corners)
                    ctx.strokeStyle = "#ff0000"
                    ctx.lineWidth = 2 / zoom
                    ctx.stroke()
                }
            })

            // Preview wall + length + angle
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

                // --- Angle calculation ---
                const dx = currentXFeet - startXFeet
                const dy = currentYFeet - startYFeet

                // Screen coordinates: Y inverted
                let rad = Math.atan2(-dy, dx)
                let angleDeg = rad * 180 / Math.PI
                if (angleDeg < 0) angleDeg += 360

                // Arc visualization
                const r = 20 / zoom
                ctx.beginPath()
                ctx.arc(x1, y1, r, 0, -rad, rad < 0) // clockwise if negative
                ctx.strokeStyle = "rgba(0,255,136,0.7)"
                ctx.lineWidth = 2 / zoom
                ctx.stroke()

                // Angle text
                ctx.fillStyle = "rgba(0,255,136,0.9)"
                ctx.font = `${12 / zoom}px sans-serif`
                ctx.textAlign = "center"
                ctx.textBaseline = "bottom"
                ctx.fillText(angleDeg.toFixed(0) + "°", x1 + r + 2 / zoom, y1 - r - 2 / zoom)

                // Length label
                const lengthFeet = Math.sqrt(dx * dx + dy * dy)
                const mx = (x1 + x2) / 2
                const my = (y1 + y2) / 2
                const label = lengthFeet.toFixed(2) + " ft"
                const tw = ctx.measureText(label).width
                const pad = 4 / zoom
                ctx.fillStyle = "rgba(0,0,0,0.7)"
                ctx.fillRect(mx - tw / 2 - pad, my - 12 / zoom, tw + pad * 2, 16 / zoom)
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
        cursorShape: (pressedButtons & Qt.RightButton) ? Qt.ClosedHandCursor : Qt.ArrowCursor

        onPressed: (mouse) => {
            root.forceActiveFocus()
            if (mouse.button === Qt.LeftButton) {
                const p = screenToFeet(mouse.x, mouse.y)
                const pickToleranceFeet = pickTolerancePixels / (pixelsPerFoot * zoom)
                let hit = -1
                let best = pickToleranceFeet
                for (let i = 0; i < walls.length; i++) {
                    const w = walls[i]
                    const d = distancePointToSegment(p.x, p.y, w.x1, w.y1, w.x2, w.y2)
                    const endToleranceFeet = 0.4
                    if (distanceToPoint(p.x, p.y, w.x1, w.y1) < endToleranceFeet ||
                        distanceToPoint(p.x, p.y, w.x2, w.y2) < endToleranceFeet)
                        continue
                    if (d < best) { best = d; hit = i }
                }
                if (hit !== -1) { selectedWall = hit; drawingWall = false }
                else { selectedWall = -1; startXFeet = p.x; startYFeet = p.y; currentXFeet = p.x; currentYFeet = p.y; drawingWall = true }
                canvas.requestPaint()
            } else if (mouse.button === Qt.RightButton) { lastX = mouse.x; lastY = mouse.y }
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
                walls.push({ x1: startXFeet, y1: startYFeet, x2: currentXFeet, y2: currentYFeet })
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
