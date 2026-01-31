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

    property var undoStack: []
    property int maxUndoSteps: 50

    // Camera
    property real zoom: 1.0
    property real pixelsPerFoot: 30
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

    property bool rotatingWall: false
    property real rotateStartAngle: 0
    property real rotateBaseAngle: 0

    property real moveStepFeet: 0.0416667     // ~0.5 inches
    property real moveStepFastFeet: 0.1  // 1.2 inches when Shift is held

    property bool resizingWall: false
    property int resizeEnd: 0   // 1 = x1/y1, 2 = x2/y2

    // Dimensions 
    property var dimensions: []   // {x1, y1, x2, y2} in FEET
    property bool drawingDimension: false
    property real dimStartXFeet: 0
    property real dimStartYFeet: 0
    property real dimCurrentXFeet: 0
    property real dimCurrentYFeet: 0

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

    function drawDimension(ctx, x1Feet, y1Feet, x2Feet, y2Feet,
                color = "#00ff88", barSizePx = 10) {

        // world → local canvas space (your ctx is already translated + scaled)
        const x1 = x1Feet * pixelsPerFoot
        const y1 = y1Feet * pixelsPerFoot
        const x2 = x2Feet * pixelsPerFoot
        const y2 = y2Feet * pixelsPerFoot

        // main line
        ctx.strokeStyle = color
        ctx.lineWidth = 2 / zoom
        ctx.beginPath()
        ctx.moveTo(x1, y1)
        ctx.lineTo(x2, y2)
        ctx.stroke()

        // end bars
        const angle = Math.atan2(y2 - y1, x2 - x1)
        const px = Math.sin(angle) * (barSizePx / zoom)
        const py = -Math.cos(angle) * (barSizePx / zoom)

        ctx.beginPath()
        ctx.moveTo(x1 - px, y1 - py)
        ctx.lineTo(x1 + px, y1 + py)
        ctx.moveTo(x2 - px, y2 - py)
        ctx.lineTo(x2 + px, y2 + py)
        ctx.stroke()

        // label
        const dx = x2Feet - x1Feet
        const dy = y2Feet - y1Feet
        const lengthFeet = Math.sqrt(dx*dx + dy*dy)
        const label = formatFeetInches(lengthFeet)

        // midpoint in world (canvas-local) space
        const mx = (x1 + x2) / 2
        const my = (y1 + y2) / 2

        // direction
        const dxp = x2 - x1
        const dyp = y2 - y1
        const len = Math.hypot(dxp, dyp) || 1

        // perpendicular normal (consistent "above")
        const nx = dyp / len
        const ny = -dxp / len

        // offset in SCREEN pixels
        const labelOffsetPx = 14
        const ox = nx * (labelOffsetPx / zoom)
        const oy = ny * (labelOffsetPx / zoom)

        // final label position (world → screen)
        ctx.save()
        ctx.setTransform(1, 0, 0, 1, 0, 0)
        const sx = (mx + ox) * zoom + offsetX
        const sy = (my + oy) * zoom + offsetY

        ctx.fillStyle = color
        ctx.font = "12px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(label, sx, sy)
        ctx.restore()
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
        if (selectedWall === -1) return
        pushUndoState()
        const w = walls[selectedWall]
        w.x1 += dxFeet
        w.y1 += dyFeet
        w.x2 += dxFeet
        w.y2 += dyFeet
        canvas.requestPaint()
    }

    function wallCenter(w) {
        return {
            x: (w.x1 + w.x2) / 2,
            y: (w.y1 + w.y2) / 2
        }
    }

    function wallAngle(w) {
        return Math.atan2(w.y2 - w.y1, w.x2 - w.x1)
    }

    function rotateWall(w, angleRad) {
        const c = wallCenter(w)
        const len = Math.hypot(w.x2 - w.x1, w.y2 - w.y1) / 2
        w.x1 = c.x - Math.cos(angleRad) * len
        w.y1 = c.y - Math.sin(angleRad) * len
        w.x2 = c.x + Math.cos(angleRad) * len
        w.y2 = c.y + Math.sin(angleRad) * len
    }

    function hitRotateHandle(p, w) {
        const c = wallCenter(w)
        const angle = wallAngle(w)
        // convert pixel distance → feet
        const handleDistFeet = (20 / zoom) / pixelsPerFoot
        const radiusFeet = (8 / zoom) / pixelsPerFoot
        const hx = c.x + Math.cos(angle + Math.PI / 2) * handleDistFeet
        const hy = c.y + Math.sin(angle + Math.PI / 2) * handleDistFeet
        return distanceToPoint(p.x, p.y, hx, hy) < radiusFeet
    }

    function hitWallEndpoint(p, w) {
        const tolFeet = (8 / zoom) / pixelsPerFoot
        if (distanceToPoint(p.x, p.y, w.x1, w.y1) < tolFeet)
            return 1
        if (distanceToPoint(p.x, p.y, w.x2, w.y2) < tolFeet)
            return 2
        return 0
    }

    function drawAngleVisualizer(ctx, cx, cy, angleRad, zoom, color) {
        let deg = angleRad * 180 / Math.PI
        if (deg < 0) deg += 360
        const r = 20 / zoom
        // Draw arc
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, -angleRad, true)
        ctx.strokeStyle = color
        ctx.lineWidth = 2 / zoom
        ctx.stroke()
        // Draw angle text
        ctx.fillStyle = color
        ctx.font = `${12 / zoom}px sans-serif`
        ctx.textAlign = "left"
        ctx.textBaseline = "middle"
        ctx.fillText(`${deg.toFixed(0)}°`, cx + r + 4 / zoom, cy)
    }

    function wallAngleForDisplay(w) {
        const dx = w.x2 - w.x1
        const dy = w.y2 - w.y1
        return Math.atan2(-dy, dx)
    }

    function formatFeetInches(lengthFeet) {
        const feet = Math.floor(lengthFeet)
        const inches = Math.round((lengthFeet - feet) * 12)
        return `${feet}'${inches}"`
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

            // Multi-level graduated grid
            const minorGridFeet = 0.25   // 3 inches
            const mediumGridFeet = 1     // 1 foot
            const majorGridFeet = 5      // 5 feet
            for (let i = -200; i <= 200; i += minorGridFeet) {
                let lineType = "minor"
                if (Math.abs(i % majorGridFeet) < 1e-6) 
                    lineType = "major"
                else if (Math.abs(i % mediumGridFeet) < 1e-6) 
                    lineType = "medium"

                switch(lineType) {
                    case "minor":
                        ctx.strokeStyle = "#3a3a3a"
                        ctx.lineWidth = 0.5 / zoom
                        break
                    case "medium":
                        ctx.strokeStyle = "#505050"
                        ctx.lineWidth = 1 / zoom
                        break
                    case "major":
                        ctx.strokeStyle = "#707070"
                        ctx.lineWidth = 2 / zoom
                        break
                }
                // vertical line
                ctx.beginPath()
                ctx.moveTo(i * pixelsPerFoot, -10000)
                ctx.lineTo(i * pixelsPerFoot, 10000)
                ctx.stroke()
                // horizontal line
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
                    // rotation handle
                    const mx = (g.x1 + g.x2) / 2
                    const my = (g.y1 + g.y2) / 2
                    const handleDist = 20 / zoom
                    const angle = wallAngle(w)
                    const hx = mx + Math.cos(angle + Math.PI / 2) * handleDist
                    const hy = my + Math.sin(angle + Math.PI / 2) * handleDist
                    ctx.beginPath()
                    ctx.arc(hx, hy, 5 / zoom, 0, Math.PI * 2)
                    ctx.fillStyle = "#ff5555"
                    ctx.fill()
                    // endpoint resize handles
                    ctx.fillStyle = "#00aaff"
                    ctx.beginPath()
                    ctx.arc(g.x1, g.y1, 5 / zoom, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.beginPath()
                    ctx.arc(g.x2, g.y2, 5 / zoom, 0, Math.PI * 2)
                    ctx.fill()
                    // Length label while resizing
                    if (resizingWall) {
                        let x1 = w.x1
                        let y1 = w.y1
                        let x2 = w.x2
                        let y2 = w.y2
                        // if resizing one endpoint, use current mouse pos
                        if (resizeEnd === 1) {
                            x1 = currentXFeet
                            y1 = currentYFeet
                        } else if (resizeEnd === 2) {
                            x2 = currentXFeet
                            y2 = currentYFeet
                        }
                        const dx = x2 - x1
                        const dy = y2 - y1
                        const lengthFeet = Math.sqrt(dx*dx + dy*dy)
                        const label = formatFeetInches(lengthFeet)
                        const mx = ((x1 + x2) / 2) * pixelsPerFoot
                        const my = ((y1 + y2) / 2) * pixelsPerFoot

                        ctx.save()
                        ctx.setTransform(1, 0, 0, 1, 0, 0) // reset to screen space
                        // convert wall-local coords to screen coords
                        const sx = mx * zoom + offsetX
                        const sy = my * zoom + offsetY
                        ctx.globalAlpha = 1.0       // ensure full opacity
                        ctx.fillStyle = "#000000"   // black text
                        ctx.strokeStyle = "rgba(0,0,0,0)" // no stroke background
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillText(label, sx, sy)
                        ctx.restore()
                    }
                    // angle visualizer while rotating
                    if (rotatingWall) {
                        const c = wallCenter(w)
                        const a = wallAngleForDisplay(w)
                        const cx = c.x * pixelsPerFoot
                        const cy = c.y * pixelsPerFoot
                        drawAngleVisualizer(ctx, cx, cy, a, zoom, "#00ff88")
                    }
                }
            })

            // Preview wall
            if (drawingWall) {
                const tempWall = {x1:startXFeet,y1:startYFeet,x2:currentXFeet,y2:currentYFeet}
                const g = wallGeometry(tempWall)
                if (!g) return
                // Preview line (screen-space dashed line)
                const sx1 = g.x1 * zoom + offsetX
                const sy1 = g.y1 * zoom + offsetY
                const sx2 = g.x2 * zoom + offsetX
                const sy2 = g.y2 * zoom + offsetY
                ctx.save()
                ctx.setTransform(1, 0, 0, 1, 0, 0) // reset to screen space
                ctx.strokeStyle = "#00ff88"
                ctx.lineWidth = 2
                ctx.setLineDash([6, 6])
                ctx.beginPath()
                ctx.moveTo(sx1, sy1)
                ctx.lineTo(sx2, sy2)
                ctx.stroke()
                ctx.setLineDash([])
                ctx.restore()
                // Angle visualization
                const dx = currentXFeet - startXFeet
                const dy = currentYFeet - startYFeet
                let rad = Math.atan2(dy, dx)
                drawAngleVisualizer(ctx, g.x1, g.y1, -rad, zoom, "#00ff88")
                // Length label
                const mx = (g.x1 + g.x2) / 2
                const my = (g.y1 + g.y2) / 2
                const lengthFeet = Math.sqrt(dx*dx + dy*dy)
                const label = formatFeetInches(lengthFeet)
                const tw = ctx.measureText(label).width
                const pad = 4 / zoom
                ctx.fillStyle = "rgba(0,0,0,0.7)"
                ctx.fillRect(mx - tw / 2 - pad, my - 12 / zoom, tw + pad * 2, 16 / zoom)
                ctx.fillStyle = "#00ff88"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(label, mx, my)
            }

            // Existing dimensions
            dimensions.forEach(d => {
                drawDimension(ctx, d.x1, d.y1, d.x2, d.y2)
            })

            // Dimension preview while drawing
            if (drawingDimension) {
                drawDimension(
                    ctx,
                    dimStartXFeet,
                    dimStartYFeet,
                    dimCurrentXFeet,
                    dimCurrentYFeet,
                    "#00ffaa"
                )
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
            // START DIMENSION (Shift + Right Click)
            if ((mouse.modifiers & Qt.ShiftModifier) &&
                mouse.button === Qt.RightButton) {
                const p = screenToFeet(mouse.x, mouse.y)
                drawingDimension = true
                dimStartXFeet = p.x
                dimStartYFeet = p.y
                dimCurrentXFeet = p.x
                dimCurrentYFeet = p.y
                return
            }
            if (mouse.button === Qt.LeftButton) {
                const p = screenToFeet(mouse.x, mouse.y)
                // RESIZE HANDLE FIRST
                if (selectedWall !== -1) {
                    const w = walls[selectedWall]
                    const end = hitWallEndpoint(p, w)
                    if (end !== 0) {
                        pushUndoState()
                        resizingWall = true
                        resizeEnd = end
                        return
                    }
                }
                // CHECK ROTATION HANDLE NEXT
                if (selectedWall !== -1) {
                    const w = walls[selectedWall]
                    if (hitRotateHandle(p, w)) {
                        pushUndoState()
                        rotatingWall = true
                        rotateBaseAngle = wallAngle(w)
                        rotateStartAngle = Math.atan2(
                            p.y - wallCenter(w).y,
                            p.x - wallCenter(w).x
                        )
                        return   // stop normal selection logic
                    }
                }
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
            if (drawingDimension && (mouse.buttons & Qt.RightButton)) {
                const p = screenToFeet(mouse.x, mouse.y)
                dimCurrentXFeet = p.x
                dimCurrentYFeet = p.y
                canvas.requestPaint()
                return
            }            
            // RESIZE SELECTED WALL (ENDPOINT DRAG)
            if (resizingWall && (mouse.buttons & Qt.LeftButton)) {
                const p = screenToFeet(mouse.x, mouse.y)
                const w = walls[selectedWall]
                if (resizeEnd === 1) {
                    w.x1 = p.x
                    w.y1 = p.y
                    currentXFeet = p.x
                    currentYFeet = p.y
                } else if (resizeEnd === 2) {
                    w.x2 = p.x
                    w.y2 = p.y
                    currentXFeet = p.x
                    currentYFeet = p.y
                }
                canvas.requestPaint()
                return
            }
            if (rotatingWall && (mouse.buttons & Qt.LeftButton)) {
                const p = screenToFeet(mouse.x, mouse.y)
                const w = walls[selectedWall]
                const currentAngle = Math.atan2(
                    p.y - wallCenter(w).y,
                    p.x - wallCenter(w).x
                )
                const delta = currentAngle - rotateStartAngle
                rotateWall(w, rotateBaseAngle + delta)
                canvas.requestPaint()
            } else if (drawingWall && (mouse.buttons & Qt.LeftButton)) {
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
            if (drawingDimension && mouse.button === Qt.RightButton) {
                const dx = dimCurrentXFeet - dimStartXFeet
                const dy = dimCurrentYFeet - dimStartYFeet
                // prevent zero-length dimensions
                if (Math.hypot(dx, dy) > 0.1) {
                    dimensions.push({
                        x1: dimStartXFeet,
                        y1: dimStartYFeet,
                        x2: dimCurrentXFeet,
                        y2: dimCurrentYFeet
                    })
                }
                drawingDimension = false
                canvas.requestPaint()
                return
            }
            if (resizingWall) {
                resizingWall = false
                resizeEnd = 0
                return
            }
            if (rotatingWall) {
                rotatingWall = false
            } else if (drawingWall && mouse.button === Qt.LeftButton) {
                const dx = currentXFeet - startXFeet
                const dy = currentYFeet - startYFeet
                // drop zero-length “click” walls to be selected/created
                if (Math.hypot(dx, dy) < 0.1) {
                    drawingWall = false
                    canvas.requestPaint()
                    return
                }
                pushUndoState()
                walls.push({
                    x1: startXFeet,
                    y1: startYFeet,
                    x2: currentXFeet,
                    y2: currentYFeet
                })
                //select the newly created wall
                selectedWall = walls.length - 1
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
