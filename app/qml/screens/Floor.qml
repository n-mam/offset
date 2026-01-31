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
    property real wallThicknessFeet: 0.5 // 6 inches

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
    property real pickTolerancePixels: 8 // feels good: 6–10 px

    property var undoStack: []
    property int maxUndoSteps: 50

    property real moveStepFeet: 0.0416667     // ~0.5 inches
    property real moveStepFastFeet: 0.1  // 1.2 inches when Shift is held

    function screenToFeet(x, y) {
        const px = (x - offsetX) / zoom
        const py = (y - offsetY) / zoom
        return { x: px / pixelsPerFoot, y: py / pixelsPerFoot }
    }

    function wallGeometry(w) {
        const dx = w.x2 - w.x1
        const dy = w.y2 - w.y1
        const len = Math.hypot(dx, dy)
        if (len  ===  0) return null

        const tx = dx / len
        const ty = dy / len
        const nx = -ty
        const ny = tx

        const halfThicknessPx = (wallThicknessFeet / 2) * pixelsPerFoot
        const pxLen = len * pixelsPerFoot

        const x1 = w.x1 * pixelsPerFoot
        const y1 = w.y1 * pixelsPerFoot

        return {
            len: len,
            tx: tx, ty: ty,
            nx: nx, ny: ny,
            x1: x1, y1: y1,
            x2: x1 + tx * pxLen,
            y2: y1 + ty * pxLen,
            corners: [
                { x: x1 + nx * halfThicknessPx, y: y1 + ny * halfThicknessPx },
                { x: x1 + tx * pxLen + nx * halfThicknessPx, y: y1 + ty * pxLen + ny * halfThicknessPx },
                { x: x1 + tx * pxLen - nx * halfThicknessPx, y: y1 + ty * pxLen - ny * halfThicknessPx },
                { x: x1 - nx * halfThicknessPx, y: y1 - ny * halfThicknessPx }
            ]
        }
    }

    function polygonPath(ctx, corners) {
        ctx.beginPath()
        ctx.moveTo(corners[0].x, corners[0].y)
        for (let i = 1; i < corners.length; i++)
            ctx.lineTo(corners[i].x, corners[i].y)
        ctx.closePath()
    }

    function drawWallRect(ctx, w) {
        const g = wallGeometry(w)
        if (!g) return

        polygonPath(ctx, g.corners)
        ctx.fillStyle = wallFillColor
        ctx.fill()

        ctx.save()
        polygonPath(ctx, g.corners)
        ctx.clip()

        const spacing = 6 / zoom
        const hatchAngle = Math.PI / 4
        const cosA = Math.cos(hatchAngle)
        const sinA = Math.sin(hatchAngle)

        const xs = g.corners.map(c => c.x)
        const ys = g.corners.map(c => c.y)
        const minX = Math.min.apply(null, xs)
        const maxX = Math.max.apply(null, xs)
        const minY = Math.min.apply(null, ys)
        const maxY = Math.max.apply(null, ys)
        const diagLen = Math.hypot(maxX - minX, maxY - minY)

        ctx.strokeStyle = hatchStrokeColor
        ctx.lineWidth = 1 / zoom
        for (let i = -diagLen; i < diagLen * 2; i += spacing) {
            ctx.beginPath()
            ctx.moveTo(minX + i * (-sinA), minY + i * cosA)
            ctx.lineTo(minX + i * (-sinA) + diagLen * cosA, minY + i * cosA + diagLen * sinA)
            ctx.stroke()
        }

        ctx.restore()
        polygonPath(ctx, g.corners)
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
        if (c1 <= 0) 
            return Math.hypot(px - x1, py - y1)
        const c2 = vx * vx + vy * vy
        if (c2 <= c1)
            return Math.hypot(px - x2, py - y2)
        const b = c1 / c2
        return Math.hypot(px - (x1 + b * vx), py - (y1 + b * vy))
    }

    function pushUndoState() {
        if (undoStack.length >= maxUndoSteps)
            undoStack.shift()
        undoStack.push(walls.map(w => Object.assign({}, w)))
    }

    function moveSelectedWall(dxFeet, dyFeet) {
        if (selectedWall === -1)
            return
        pushUndoState()
        const w = walls[selectedWall]
        w.x1 += dxFeet
        w.y1 += dyFeet
        w.x2 += dxFeet
        w.y2 += dyFeet
        canvas.requestPaint()
    }

    Rectangle { anchors.fill: parent; color: "#1e1e1e" }

    Canvas {
        id: canvas
        anchors.fill: parent
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
                    const g = wallGeometry(w)
                    if (!g) return
                    polygonPath(ctx, g.corners)
                    ctx.strokeStyle = "#ff0000"
                    ctx.lineWidth = 2 / zoom
                    ctx.stroke()
                }
            })

            // Preview wall
            if (drawingWall) {
                const tempWall = {x1:startXFeet,y1:startYFeet,x2:currentXFeet,y2:currentYFeet}
                const g = wallGeometry(tempWall)
                if (!g) return
                // Preview line
                ctx.strokeStyle = "#00ff88"
                ctx.lineWidth = 2 / zoom
                ctx.setLineDash([6 / zoom, 6 / zoom])
                ctx.beginPath()
                ctx.moveTo(g.x1, g.y1)
                ctx.lineTo(g.x2, g.y2)
                ctx.stroke()
                ctx.setLineDash([])
                // Angle visualization
                const dx = currentXFeet - startXFeet
                const dy = currentYFeet - startYFeet
                let rad = Math.atan2(-dy, dx)
                let angleDeg = rad * 180 / Math.PI
                if (angleDeg < 0)
                    angleDeg += 360
                const r = 20 / zoom
                ctx.beginPath()
                ctx.arc(g.x1, g.y1, r, 0, -rad, rad < 0)
                ctx.strokeStyle = "rgba(0,255,136,0.7)"
                ctx.lineWidth = 2 / zoom
                ctx.stroke()

                ctx.fillStyle = "rgba(0,255,136,0.9)"
                ctx.font = `${12 / zoom}px sans-serif`
                ctx.textAlign = "center"
                ctx.textBaseline = "bottom"
                ctx.fillText(`${angleDeg.toFixed(0)}°`, g.x1 + r + 2 / zoom, g.y1 - r - 2 / zoom)

                // Length label
                const mx = (g.x1 + g.x2) / 2
                const my = (g.y1 + g.y2) / 2
                const lengthFeet = Math.sqrt(dx*dx + dy*dy)
                const label = `${lengthFeet.toFixed(2)} ft`
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

    MouseArea {
        property real lastX
        property real lastY
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton|Qt.RightButton
        onPressed: mouse => {
            root.forceActiveFocus()
            if (mouse.button === Qt.LeftButton) {
                const p = screenToFeet(mouse.x, mouse.y)
                let hit = -1
                let best = pickTolerancePixels/(pixelsPerFoot*zoom)
                for (let i = 0; i < walls.length; i++) {
                    const w = walls[i]
                    const d = distancePointToSegment(p.x, p.y, w.x1, w.y1, w.x2, w.y2)
                    const endToleranceFeet = 1.5
                    if (distanceToPoint(p.x, p.y, w.x1, w.y1) < endToleranceFeet ||
                        distanceToPoint(p.x, p.y, w.x2, w.y2) < endToleranceFeet)
                            continue
                    if (d < best) {
                        best = d
                        hit = i
                    }
                }
                if (hit !== -1) { 
                    selectedWall = hit
                    drawingWall = false
                } else {
                    selectedWall = -1
                    startXFeet = p.x
                    startYFeet = p.y
                    currentXFeet = p.x
                    currentYFeet = p.y
                    drawingWall = true
                }
                canvas.requestPaint()
            } else {
                lastX = mouse.x
                lastY = mouse.y
            }
        }

        onPositionChanged: mouse => {
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
                canvas.requestPaint()
            }
        }

        onReleased: mouse => {
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

        onWheel: wheel => {
            zoom = Math.max(0.2, Math.min(5, zoom*(wheel.angleDelta.y > 0 ? 1.1 : 0.9)))
            canvas.requestPaint()
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

    Keys.onPressed: event => {
        const step = (event.modifiers & Qt.ShiftModifier) ?
                    moveStepFastFeet : moveStepFeet
        switch (event.key) {
            case Qt.Key_Left:
                moveSelectedWall(-step, 0)
                event.accepted = true
                break
            case Qt.Key_Right:
                moveSelectedWall(step, 0)
                event.accepted = true
                break
            case Qt.Key_Up:
                moveSelectedWall(0, -step) // Y grows downward in screen space
                event.accepted = true
                break
            case Qt.Key_Down:
                moveSelectedWall(0, step)
                event.accepted = true
                break
            case Qt.Key_Z:
                if (event.modifiers & Qt.ControlModifier) {
                    if (undoStack.length > 0) {
                        walls = undoStack.pop()
                        selectedWall = -1
                        canvas.requestPaint()
                    }
                    event.accepted = true
                }
                break
        }
    }
}
