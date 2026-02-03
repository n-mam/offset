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

    property var shapes: []
    property real wallThicknessFeet: 0.5 // 6 inches

    property int selected: -1
    property real pickTolerancePixels: 8 // feels good: 6–10 px

    property bool rotating: false
    property real rotateStartAngle: 0
    property real rotateBaseAngle: 0

    property real moveStepFeet: 0.0416667 // ~0.5 inches
    property real moveStepFastFeet: 0.1  // 1.2 inches when Shift is held

    property bool resizing: false
    property int resizeEnd: 0   // 1 = x1/y1, 2 = x2/y2

    property var drawing: ({
        type: "",
        active: false,
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0
    })

    // ---- Coordinate spaces ----
    // World: feet
    // Canvas: pixels, before zoom/offset
    // Screen: pixels, after zoom/offset

    property var gridLevels: [
        { step: 0.25, color: "#3a3a3a", width: 0.5 },
        { step: 1,    color: "#505050", width: 1   },
        { step: 5,    color: "#707070", width: 2   }
    ]

    // Colors
    property var colors: ({
        wallFill: "#dcd0aa",
        wallOutline: "rgba(120,95,60,0.6)",
        hatchStroke: "rgba(140,110,70,0.6)",
        selected: "#ff0000",
        preview: "#00ff88",
        rotateHandle: "#ff5555",
        resizeHandle: "#00aaff"
    })

    function shapeGeometry(s) {
        let x1, y1, x2, y2, thicknessFeet;
        switch(s.type) {
            case "wall":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                thicknessFeet = wallThicknessFeet;
                break;
            case "door":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                // approximate thickness as the "door leaf width" (feet)
                thicknessFeet = s.width || 0.5; 
                break;
            case "dimension":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                const barSizePx = 10; // same as in drawDimension
                thicknessFeet = (barSizePx / zoom) / pixelsPerFoot; // end bar height in feet
                break;
            default:
                return null;
        }

        const dx = x2 - x1;
        const dy = y2 - y1;
        const len = Math.hypot(dx, dy);
        if(len === 0) return null;

        const tx = dx / len;
        const ty = dy / len;
        const nx = -ty;
        const ny = tx;

        const halfThicknessPx = (thicknessFeet / 2) * pixelsPerFoot;
        const pxLen = len * pixelsPerFoot;

        const x1Px = x1 * pixelsPerFoot;
        const y1Px = y1 * pixelsPerFoot;

        return {
            len: len,
            tx: tx, ty: ty,
            nx: nx, ny: ny,
            x1: x1Px, y1: y1Px,
            x2: x1Px + tx * pxLen,
            y2: y1Px + ty * pxLen,
            corners: [
                { x: x1Px + nx * halfThicknessPx, y: y1Px + ny * halfThicknessPx },
                { x: x1Px + tx * pxLen + nx * halfThicknessPx, y: y1Px + ty * pxLen + ny * halfThicknessPx },
                { x: x1Px + tx * pxLen - nx * halfThicknessPx, y: y1Px + ty * pxLen - ny * halfThicknessPx },
                { x: x1Px - nx * halfThicknessPx, y: y1Px - ny * halfThicknessPx }
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

    function drawWallRect(ctx, g) {
        polygonPath(ctx, g.corners)
        ctx.fillStyle = colors.wallFill
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

        ctx.strokeStyle = colors.hatchStroke
        ctx.lineWidth = 1 / zoom
        for (let i = -diagLen; i < diagLen * 2; i += spacing) {
            ctx.beginPath()
            ctx.moveTo(minX + i * (-sinA), minY + i * cosA)
            ctx.lineTo(minX + i * (-sinA) + diagLen * cosA, minY + i * cosA + diagLen * sinA)
            ctx.stroke()
        }

        ctx.restore()
        polygonPath(ctx, g.corners)
        ctx.strokeStyle = colors.wallOutline
        ctx.lineWidth = 1 / zoom
        ctx.stroke()
    }

    function drawDoor(ctx, door, preview = false) {
        const x1 = door.x1 * pixelsPerFoot;
        const y1 = door.y1 * pixelsPerFoot;
        const x2 = door.x2 * pixelsPerFoot;
        const y2 = door.y2 * pixelsPerFoot;
        const w = Math.hypot(x2 - x1, y2 - y1);
        const a = Math.atan2(y2 - y1, x2 - x1);

        ctx.save();
        ctx.fillStyle = preview ? "rgba(0, 255, 136, 0.2)" : "rgba(255, 255, 255, 0.15)";
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.arc(x1, y1, w, a, a + Math.PI / 2);
        ctx.closePath();
        ctx.fill();

        ctx.lineWidth = 6 / zoom;
        ctx.strokeStyle = preview ? colors.preview : "#ffffff";
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();

        ctx.lineWidth = 2 / zoom;
        ctx.setLineDash([1.5 / zoom, 1.5 / zoom]);
        ctx.beginPath();
        ctx.arc(x1, y1, w, a, a + Math.PI / 2);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.restore();
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
            return distanceToPoint(px, py, x1, y1)
        const c2 = vx * vx + vy * vy
        if (c2 <= c1)
            return distanceToPoint(px, py, x2, y2)
        const b = c1 / c2
        return distanceToPoint(px, py, (x1 + b * vx), (y1 + b * vy))
    }

    function pushUndoState() {
        if (undoStack.length >= maxUndoSteps)
            undoStack.shift()
        undoStack.push({
            shapes: shapes.map(s => Object.assign({}, s)),
        })
    }

    function moveSelected(dxFeet, dyFeet) {
        if (selected === -1) return
        pushUndoState()
        const w = shapes[selected]
        w.x1 += dxFeet
        w.y1 += dyFeet
        w.x2 += dxFeet
        w.y2 += dyFeet
        canvas.requestPaint()
    }

    function shapeCenter(w) {
        return {
            x: (w.x1 + w.x2) / 2,
            y: (w.y1 + w.y2) / 2
        }
    }

    function shapeAngle(w) {
        return Math.atan2(w.y2 - w.y1, w.x2 - w.x1)
    }

    function rotateShape(w, angleRad) {
        const c = shapeCenter(w)
        const len = distanceToPoint(w.x2, w.y2, w.x1, w.y1) / 2
        w.x1 = c.x - Math.cos(angleRad) * len
        w.y1 = c.y - Math.sin(angleRad) * len
        w.x2 = c.x + Math.cos(angleRad) * len
        w.y2 = c.y + Math.sin(angleRad) * len
    }

    function hitRotateHandle(p, w) {
        const c = shapeCenter(w)
        const angle = shapeAngle(w)
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

    function wallAngleForDisplay(w) {
        const dx = w.x2 - w.x1
        const dy = w.y2 - w.y1
        return Math.atan2(-dy, dx)
    }

    function formatFeetInches(lengthFeet) {
        let feet = Math.floor(lengthFeet)
        let inches = Math.round((lengthFeet - feet) * 12)
        if (inches === 12) {
            feet++
            inches = 0
        }
        return `${feet}'${inches}"`
    }

    function worldToCanvas(p) {
        return {
            x: p.x * pixelsPerFoot,
            y: p.y * pixelsPerFoot
        }
    }

    function canvasToWorld(p) {
        return {
            x: p.x / pixelsPerFoot,
            y: p.y / pixelsPerFoot
        }
    }

    function canvasToScreen(p) {
        return {
            x: p.x * zoom + offsetX,
            y: p.y * zoom + offsetY
        }
    }

    function screenToCanvas(p) {
        return {
            x: (p.x - offsetX) / zoom,
            y: (p.y - offsetY) / zoom
        }
    }

    function worldToScreen(p) {
        return canvasToScreen(worldToCanvas(p))
    }

    function screenToWorld(x, y) {
        return canvasToWorld(screenToCanvas({ x, y }))
    }

    function drawGrid(ctx) {
        gridLevels.forEach(level => {
            ctx.strokeStyle = level.color
            ctx.lineWidth = level.width / zoom
            for (let i = -200; i <= 200; i += level.step) {
                ctx.beginPath()
                ctx.moveTo(i * pixelsPerFoot, -10000)
                ctx.lineTo(i * pixelsPerFoot,  10000)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(-10000, i * pixelsPerFoot)
                ctx.lineTo( 10000, i * pixelsPerFoot)
                ctx.stroke()
            }
        })
    }

    function annotateShape(ctx, g, s) {
        polygonPath(ctx, g.corners)
        ctx.strokeStyle = colors.selected
        ctx.lineWidth = 2 / zoom
        ctx.stroke()
        // rotation handle
        const mx = (g.x1 + g.x2) / 2
        const my = (g.y1 + g.y2) / 2
        const handleDist = 20 / zoom
        const angle = shapeAngle(s)
        const hx = mx + Math.cos(angle + Math.PI / 2) * handleDist
        const hy = my + Math.sin(angle + Math.PI / 2) * handleDist
        ctx.beginPath()
        ctx.arc(hx, hy, 5 / zoom, 0, Math.PI * 2)
        ctx.fillStyle = colors.rotateHandle
        ctx.fill()
        // endpoint resize handles
        ctx.fillStyle = colors.resizeHandle
        ctx.beginPath()
        ctx.arc(g.x1, g.y1, 5 / zoom, 0, Math.PI * 2)
        ctx.fill()
        ctx.beginPath()
        ctx.arc(g.x2, g.y2, 5 / zoom, 0, Math.PI * 2)
        ctx.fill()
        // Length label while resizing
        if (resizing) {
            let x1 = s.x1
            let y1 = s.y1
            let x2 = s.x2
            let y2 = s.y2
            // if resizing one endpoint, use current mouse pos
            if (resizeEnd === 1) {
                x1 = s.x1
                y1 = s.y1
            } else if (resizeEnd === 2) {
                x2 = s.x2
                y2 = s.y2
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
            const p = canvasToScreen({x: mx, y: my})
            ctx.globalAlpha = 1.0  // ensure full opacity
            ctx.fillStyle = "#000000" // black text
            ctx.strokeStyle = "rgba(0,0,0,0)" // no stroke background
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText(label, p.x, p.y)
            ctx.restore()
        }
        // angle visualizer while rotating
        if (rotating) {
            const c = shapeCenter(s)
            const a = wallAngleForDisplay(s)
            const cx = c.x * pixelsPerFoot
            const cy = c.y * pixelsPerFoot
            drawAngleVisualizer(ctx, cx, cy, a, zoom)
        }
    }

    function drawPreviews(ctx) {
        // Preview wall
        if (drawing.active && drawing.type === "wall") {
            const tempWall = {type: "wall", x1: drawing.startX, y1: drawing.startY, x2: drawing.currentX, y2: drawing.currentY}
            const g = shapeGeometry(tempWall)
            if (!g) return
            // Preview line (screen-space dashed line)
            ctx.save()
            ctx.strokeStyle = colors.preview
            ctx.lineWidth = 2 / zoom
            ctx.setLineDash([6 / zoom, 6 / zoom])
            ctx.beginPath()
            ctx.moveTo(g.x1, g.y1)
            ctx.lineTo(g.x2, g.y2)
            ctx.stroke()
            ctx.setLineDash([])
            ctx.restore()
            // Angle visualization
            const dx = drawing.currentX - drawing.startX
            const dy = drawing.currentY - drawing.startY
            let rad = Math.atan2(dy, dx)
            drawAngleVisualizer(ctx, g.x1, g.y1, -rad, zoom)
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
        // Dimension preview while drawing
        if (drawing.active && drawing.type === "dimension") {
            drawDimension(
                ctx,
                drawing.startX,
                drawing.startY,
                drawing.currentX,
                drawing.currentY
            )
        }
    }

    function drawAngleVisualizer(ctx, cx, cy, angleRad, zoom) {
        let deg = angleRad * 180 / Math.PI
        if (deg < 0) deg += 360
        const r = 20 / zoom
        // Draw arc
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, -angleRad, true)
        ctx.strokeStyle = colors.preview
        ctx.lineWidth = 2 / zoom
        ctx.stroke()
        // Draw angle text
        ctx.fillStyle = colors.preview
        ctx.font = `${12 / zoom}px sans-serif`
        ctx.textAlign = "left"
        ctx.textBaseline = "middle"
        ctx.fillText(`${deg.toFixed(0)}°`, cx + r + 4 / zoom, cy)
    }

    function drawDimension(ctx, x1Feet, y1Feet, x2Feet, y2Feet, barSizePx = 10) {
        // world → local canvas space (your ctx is already translated + scaled)
        const x1 = x1Feet * pixelsPerFoot
        const y1 = y1Feet * pixelsPerFoot
        const x2 = x2Feet * pixelsPerFoot
        const y2 = y2Feet * pixelsPerFoot

        // main line
        ctx.strokeStyle = colors.preview
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
        const p = canvasToScreen({ x: mx + ox, y: my + oy })
        ctx.fillStyle = colors.preview
        ctx.font = "12px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(label, p.x, p.y)
        ctx.restore()
    }

    function drawDoorPreview(ctx) {
        if (!drawing.active || drawing.type !== "door") return
        const dx = drawing.currentX - drawing.startX
        const dy = drawing.currentY - drawing.startY
        drawDoor(ctx, {
            x: drawing.startX,
            y: drawing.startY,
            width: Math.hypot(dx, dy),
            angle: Math.atan2(dy, dx)
        }, true)
    }

    Rectangle { anchors.fill: parent; color: "#1e1e1e" }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, canvas.width, canvas.height)
            // camera transform
            ctx.save()
            ctx.translate(offsetX, offsetY)
            ctx.scale(zoom, zoom)
            // Draw objects
            drawGrid(ctx)
            shapes.forEach((s, i) => {
                if (s.type == "wall") {
                    const g = shapeGeometry(s)
                    if (!g) return
                    drawWallRect(ctx, g)
                } else if (s.type == "door") {
                    drawDoor(ctx, s)
                } else if (s.type == "dimension") {
                    drawDimension(ctx, s.x1, s.y1, s.x2, s.y2)
                }
                if (i === selected) {
                    const g = shapeGeometry(s)
                    if (g) annotateShape(ctx, g, s)
                }
            })
            drawPreviews(ctx)
            drawDoorPreview(ctx)
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
            // START Door
            if ((mouse.modifiers & Qt.ControlModifier) &&
                mouse.button === Qt.LeftButton) {
                    const p = screenToWorld(mouse.x, mouse.y)
                    drawing.type = "door"
                    drawing.active = true
                    drawing.startX = p.x
                    drawing.startY = p.y
                    drawing.currentX = p.x
                    drawing.currentY = p.y
                    return
            }
            // START DIMENSION (Shift + Right Click)
            if ((mouse.modifiers & Qt.ShiftModifier) &&
                    mouse.button === Qt.LeftButton) {
                const p = screenToWorld(mouse.x, mouse.y)
                // push undo before starting the dimension
                pushUndoState()
                drawing.type = "dimension"
                drawing.active = true
                drawing.startX = p.x
                drawing.startY = p.y
                drawing.currentX = p.x
                drawing.currentY = p.y
                return
            }
            if (mouse.button === Qt.LeftButton) {
                const p = screenToWorld(mouse.x, mouse.y)
                // RESIZE HANDLE FIRST
                if (selected !== -1) {
                    const s = shapes[selected]
                    const end = hitWallEndpoint(p, s)
                    if (end !== 0) {
                        pushUndoState()
                        resizing = true
                        resizeEnd = end
                        return
                    }
                }
                // CHECK ROTATION HANDLE NEXT
                if (selected !== -1) {
                    const w = shapes[selected]
                    if (hitRotateHandle(p, w)) {
                        pushUndoState()
                        rotating = true
                        rotateBaseAngle = shapeAngle(w)
                        rotateStartAngle = Math.atan2(
                            p.y - shapeCenter(w).y,
                            p.x - shapeCenter(w).x
                        )
                        return   // stop normal selection logic
                    }
                }
                let hit = -1
                let best = pickTolerancePixels/(pixelsPerFoot*zoom)
                for (let i = 0; i < shapes.length; i++) {
                    const s = shapes[i]
                    const d = distancePointToSegment(p.x, p.y, s.x1, s.y1, s.x2, s.y2)
                    const endToleranceFeet = 1.5
                    if (distanceToPoint(p.x, p.y, s.x1, s.y1) < endToleranceFeet ||
                        distanceToPoint(p.x, p.y, s.x2, s.y2) < endToleranceFeet)
                            continue
                    if (d < best) {
                        best = d
                        hit = i
                    }
                }
                if (hit !== -1) {
                    selected = hit
                    drawing.active = false
                } else {
                    selected = -1
                    drawing.type = "wall"
                    drawing.active = true
                    drawing.startX = p.x
                    drawing.startY = p.y
                    drawing.currentX = p.x
                    drawing.currentY = p.y
                }
                canvas.requestPaint()
            } else {
                lastX = mouse.x
                lastY = mouse.y
            }
        }

        onPositionChanged: mouse => {
            if (drawing.active && (mouse.buttons & Qt.LeftButton)) {
                const p = screenToWorld(mouse.x, mouse.y)
                drawing.currentX = p.x
                drawing.currentY = p.y
                canvas.requestPaint()
                return;
            }
            // RESIZE SELECTED WALL (ENDPOINT DRAG)
            if (resizing && (mouse.buttons & Qt.LeftButton)) {
                const p = screenToWorld(mouse.x, mouse.y)
                const w = shapes[selected]
                if (resizeEnd === 1) {
                    w.x1 = p.x
                    w.y1 = p.y
                } else if (resizeEnd === 2) {
                    w.x2 = p.x
                    w.y2 = p.y
                }
                canvas.requestPaint()
                return
            }
            if (rotating && (mouse.buttons & Qt.LeftButton)) {
                const p = screenToWorld(mouse.x, mouse.y)
                const w = shapes[selected]
                const currentAngle = Math.atan2(
                    p.y - shapeCenter(w).y,
                    p.x - shapeCenter(w).x
                )
                const delta = currentAngle - rotateStartAngle
                rotateShape(w, rotateBaseAngle + delta)
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
            if (drawing.active && mouse.button === Qt.LeftButton) {
                const dx = drawing.currentX - drawing.startX
                const dy = drawing.currentY - drawing.startY
                if (drawing.type === "wall") {
                    if (Math.hypot(dx, dy) >= 0.1) {
                        pushUndoState()
                        shapes.push({
                            type: "wall",
                            x1: drawing.startX,
                            y1: drawing.startY,
                            x2: drawing.currentX,
                            y2: drawing.currentY
                        })
                        selected = shapes.length - 1
                    }
                } else if (drawing.type === "door") {
                    pushUndoState()
                    shapes.push({
                        type: "door",
                        x1: drawing.startX,
                        y1: drawing.startY,
                        x2: drawing.currentX,
                        y2: drawing.currentY,
                        width: Math.hypot(drawing.currentX - drawing.startX, drawing.currentY - drawing.startY),
                        angle: Math.atan2(drawing.currentY - drawing.startY, drawing.currentX - drawing.startX)
                    })
                    selected = shapes.length - 1
                } else if (drawing.type === "dimension") {
                    if (Math.hypot(dx, dy) > 0.1) {
                        pushUndoState()
                        shapes.push({
                            type: "dimension",
                            x1: drawing.startX,
                            y1: drawing.startY,
                            x2: drawing.currentX,
                            y2: drawing.currentY
                        })
                        selected = shapes.length - 1
                    }
                }
                drawing.active = false
                canvas.requestPaint()
                return
            }
            if (resizing) {
                resizing = false
                resizeEnd = 0
                return
            }
            if (rotating) {
                rotating = false
            }
        }

        onWheel: wheel => {
            zoom = Math.max(0.2, Math.min(5, zoom*(wheel.angleDelta.y > 0 ? 1.1 : 0.9)))
            canvas.requestPaint()
        }
    }

    Keys.onDeletePressed: {
        if (selected !== -1) {
            pushUndoState()
            shapes.splice(selected, 1)
            selected = -1
            canvas.requestPaint()
        }
    }

    Keys.onPressed: event => {
        const step = (event.modifiers & Qt.ShiftModifier) ?
                    moveStepFastFeet : moveStepFeet
        switch (event.key) {
            case Qt.Key_Left:
                moveSelected(-step, 0)
                event.accepted = true
                break
            case Qt.Key_Right:
                moveSelected(step, 0)
                event.accepted = true
                break
            case Qt.Key_Up:
                moveSelected(0, -step)
                event.accepted = true
                break
            case Qt.Key_Down:
                moveSelected(0, step)
                event.accepted = true
                break
            case Qt.Key_Z:
                if (event.modifiers & Qt.ControlModifier) {
                    if (undoStack.length > 0) {
                        const state = undoStack.pop()
                        shapes = state.shapes
                        selected = -1
                        canvas.requestPaint()
                    }
                    event.accepted = true
                }
                break
        }
    }
}