import QtQuick
import "qrc:/components"

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
    property real openingThicknessFeet: wallThicknessFeet

    property int selected: -1
    property real minDrawPixels: 6   // 4–8 px feels good
    property real pickTolerancePixels: 8 // feels good: 6–10 px

    property bool rotating: false
    property real rotateStartAngle: 0
    property real rotateBaseAngle: 0

    property real moveStepFeet: 0.0416667 // ~0.5 inches
    property real moveStepFastFeet: 0.1  // 1.2 inches when Shift is held

    property bool resizing: false
    property int resizeEnd: 0   // 1 = x1/y1, 2 = x2/y2

    property bool dragging: false
    property real dragStartX: 0
    property real dragStartY: 0
    property var dragOrigShape: null

    PropertyEditor {
        id: editor
    }

    property var drawing: ({
        type: "",
        active: false,
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0
    })

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
            case "window":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                thicknessFeet = root.openingThicknessFeet;
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

    function drawWindowRect(ctx, g, preview) {
        ctx.save();
        // fill
        polygonPath(ctx, g.corners);
        ctx.fillStyle = preview ? "rgba(180,220,255,0.4)" : "#ffffff";
        ctx.fill();
        // BLUE WINDOW BORDER (perimeter)
        polygonPath(ctx, g.corners);
        ctx.lineWidth = 1 / zoom;
        ctx.strokeStyle = "#3da5ff";
        ctx.stroke();
        // centerline (optional – keep black if you want)
        ctx.beginPath();
        ctx.moveTo(g.x1, g.y1);
        ctx.lineTo(g.x2, g.y2);
        ctx.lineWidth = 1 / zoom;
        ctx.strokeStyle = "#000000";
        ctx.stroke();
        ctx.restore();
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
        const x1 = door.x1 * pixelsPerFoot; // hinge
        const y1 = door.y1 * pixelsPerFoot;
        const x2 = door.x2 * pixelsPerFoot; // base end
        const y2 = door.y2 * pixelsPerFoot;
        const r = Math.hypot(x2 - x1, y2 - y1);
        const a = Math.atan2(y2 - y1, x2 - x1);
        // arc end point (TOP-LEFT EDGE)
        const ax = x1 + Math.cos(a + Math.PI / 2) * r;
        const ay = y1 + Math.sin(a + Math.PI / 2) * r;
        ctx.save();
        // fill
        ctx.fillStyle = preview
            ? "rgba(0,255,136,0.2)"
            : "rgba(255,255,255,0.15)";
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.arc(x1, y1, r, a, a + Math.PI / 2);
        ctx.closePath();
        ctx.fill();
        // base (thick)
        ctx.lineWidth = openingThicknessFeet * pixelsPerFoot;
        ctx.strokeStyle = "#ffffff";
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
        // TOP-LEFT radial edge (1px white) ✅
        ctx.lineWidth = 1 / zoom;
        ctx.strokeStyle = "#ffffff";
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(ax, ay);
        ctx.stroke();
        // arc
        ctx.lineWidth = 2 / zoom;
        ctx.setLineDash([1.5 / zoom, 1.5 / zoom]);
        ctx.beginPath();
        ctx.arc(x1, y1, r, a, a + Math.PI / 2);
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
        // Visible canvas bounds in *canvas-local space* (after translate+scale)
        const left   = (-offsetX) / zoom
        const right  = (canvas.width - offsetX) / zoom
        const top    = (-offsetY) / zoom
        const bottom = (canvas.height - offsetY) / zoom

        gridLevels.forEach(level => {
            const stepFeet = level.step
            const stepPx = stepFeet * pixelsPerFoot

            ctx.strokeStyle = level.color
            ctx.lineWidth = level.width / zoom

            // Clamp grid lines to visible region
            const startX = Math.floor(left / stepPx) * stepPx
            const endX   = Math.ceil(right / stepPx) * stepPx
            const startY = Math.floor(top / stepPx) * stepPx
            const endY   = Math.ceil(bottom / stepPx) * stepPx

            // Vertical lines
            for (let x = startX; x <= endX; x += stepPx) {
                ctx.beginPath()
                ctx.moveTo(x, top)
                ctx.lineTo(x, bottom)
                ctx.stroke()
            }

            // Horizontal lines
            for (let y = startY; y <= endY; y += stepPx) {
                ctx.beginPath()
                ctx.moveTo(left, y)
                ctx.lineTo(right, y)
                ctx.stroke()
            }

            // Labels only for major grid (step === 5)
            if (stepFeet === 5) {
                ctx.fillStyle = "#ffffff"
                ctx.font = `${12 / zoom}px sans-serif`

                for (let x = startX; x <= endX; x += stepPx) {
                    const value = Math.round(x / pixelsPerFoot)
                    if (value !== 0) {
                        ctx.fillText(value, x + 2 / zoom, top + 12 / zoom)
                    }
                }

                for (let y = startY; y <= endY; y += stepPx) {
                    const value = Math.round(-y / pixelsPerFoot)
                    if (value !== 0) {
                        ctx.fillText(value, left + 2 / zoom, y - 2 / zoom)
                    }
                }
            }

            // Labels for 3-inch grid at high zoom only
            if (stepFeet === 0.25 && zoom >= 2.5) {
                ctx.fillStyle = "#bbbbbb"
                ctx.font = `${10 / zoom}px sans-serif`

                for (let x = startX; x <= endX; x += stepPx) {
                    const feet = x / pixelsPerFoot
                    const inches = Math.round(feet * 12)
                    if (inches % 3 === 0 && inches !== 0) {
                        ctx.fillText(
                            `${inches}"`,
                            x + 2 / zoom,
                            top + 10 / zoom
                        )
                    }
                }

                for (let y = startY; y <= endY; y += stepPx) {
                    const feet = -y / pixelsPerFoot
                    const inches = Math.round(feet * 12)
                    if (inches % 3 === 0 && inches !== 0) {
                        ctx.fillText(
                            `${inches}"`,
                            left + 2 / zoom,
                            y - 2 / zoom
                        )
                    }
                }
            }
        })
        // Origin
        ctx.fillStyle = "#ffffff"
        ctx.beginPath()
        ctx.arc(0, 0, 4 / zoom, 0, Math.PI * 2)
        ctx.fill()
    }

    function drawWallLengthLabel(ctx, x1Feet, y1Feet, x2Feet, y2Feet, color = "#000000") {
        const dx = x2Feet - x1Feet
        const dy = y2Feet - y1Feet
        const lengthFeet = Math.hypot(dx, dy)
        if (lengthFeet === 0) return
        const label = formatFeetInches(lengthFeet)
        // midpoint in canvas space
        const mx = ((x1Feet + x2Feet) / 2) * pixelsPerFoot
        const my = ((y1Feet + y2Feet) / 2) * pixelsPerFoot
        // perpendicular offset
        const lenPx = Math.hypot(dx, dy) * pixelsPerFoot
        const ox = (dy / lenPx) * (14 / zoom)
        const oy = (-dx / lenPx) * (14 / zoom)
        // convert to screen space
        const p = canvasToScreen({ x: mx + ox, y: my + oy })
        ctx.save()
        ctx.setTransform(1, 0, 0, 1, 0, 0)
        ctx.fillStyle = color
        ctx.font = "12px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(label, p.x, p.y)
        ctx.restore()
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
        drawWallLengthLabel(
            ctx,
            s.x1, s.y1,
            s.x2, s.y2,
            "#000000")
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
        if (!drawing.active) return
        const shape = makeShape(
            drawing.type,
            drawing.startX,
            drawing.startY,
            drawing.currentX,
            drawing.currentY
        )
        if (!shape) return
        if (shape.type === "wall") {
            const g = shapeGeometry(shape)
            if (!g) return
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
            drawWallLengthLabel(
                ctx,
                shape.x1,
                shape.y1,
                shape.x2,
                shape.y2,
                colors.preview)
            const dx = shape.x2 - shape.x1
            const dy = shape.y2 - shape.y1
            drawAngleVisualizer(ctx, g.x1, g.y1, -Math.atan2(dy, dx), zoom)
        }
        else if (shape.type === "window") {
            const g = shapeGeometry(shape)
            if (!g) return
            ctx.save()
            ctx.globalAlpha = 0.6
            drawWindowRect(ctx, g, true)
            ctx.restore()
        }
        else if (shape.type === "door") {
            ctx.save()
            ctx.globalAlpha = 0.6
            drawDoor(ctx, shape, true)
            ctx.restore()
        }
        else if (shape.type === "dimension") {
            drawDimension(
                ctx,
                shape.x1,
                shape.y1,
                shape.x2,
                shape.y2
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
        // world (feet) → canvas (pixels)
        const x1 = x1Feet * pixelsPerFoot;
        const y1 = y1Feet * pixelsPerFoot;
        const x2 = x2Feet * pixelsPerFoot;
        const y2 = y2Feet * pixelsPerFoot;
        // Vector from start → end
        const dx = x2 - x1;
        const dy = y2 - y1;
        const length = Math.hypot(dx, dy) || 1; // prevent divide-by-zero
        // Main line
        ctx.strokeStyle = colors.preview;
        ctx.lineWidth = 2 / zoom;
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
        // End bars (perpendicular to main line)
        const px = (dy / length) * (barSizePx / zoom);
        const py = (-dx / length) * (barSizePx / zoom);
        ctx.beginPath();
        ctx.moveTo(x1 - px, y1 - py);
        ctx.lineTo(x1 + px, y1 + py);
        ctx.moveTo(x2 - px, y2 - py);
        ctx.lineTo(x2 + px, y2 + py);
        ctx.stroke();
        // Label text
        const lengthFeet = Math.hypot(x2Feet - x1Feet, y2Feet - y1Feet);
        const label = formatFeetInches(lengthFeet);
        // Midpoint
        const mx = (x1 + x2) / 2;
        const my = (y1 + y2) / 2;
        // Perpendicular offset for label
        const labelOffsetPx = 14 / zoom;
        const ox = (dy / length) * labelOffsetPx;
        const oy = (-dx / length) * labelOffsetPx;
        // Convert midpoint + offset to screen space
        const p = canvasToScreen({ x: mx + ox, y: my + oy });
        // Draw label
        ctx.save();
        ctx.setTransform(1, 0, 0, 1, 0, 0); // reset transform for screen coords
        ctx.fillStyle = colors.preview;
        ctx.font = "12px sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(label, p.x, p.y);
        ctx.restore();
    }

    function startDrawing(type, mouse, pushUndo = false) {
        if (pushUndo) pushUndoState()
        const p = screenToWorld(mouse.x, mouse.y)
        drawing.type = type
        drawing.active = true
        drawing.startX = p.x
        drawing.startY = p.y
        drawing.currentX = p.x
        drawing.currentY = p.y
    }

    function makeShape(type, startX, startY, endX, endY) {
        const dx = endX - startX
        const dy = endY - startY
        const len = Math.hypot(dx, dy)
        if (len === 0) return null
        const base = {
            x1: startX,
            y1: startY,
            x2: endX,
            y2: endY
        }
        switch (type) {
            case "wall":
                return Object.assign({ type: "wall" }, base)
            case "door":
                return Object.assign({
                    type: "door",
                    width: len,
                    angle: Math.atan2(dy, dx)
                }, base)
            case "window":
                return Object.assign({
                    type: "window"
                }, base)
            case "dimension":
                return Object.assign({ type: "dimension" }, base)
            default:
                return null
        }
    }

    function finishDrawing() {
        const dx = drawing.currentX - drawing.startX
        const dy = drawing.currentY - drawing.startY
        const lenFeet = Math.hypot(dx, dy)
        // convert min pixels → feet (accounting for zoom)
        const minFeet = (minDrawPixels / zoom) / pixelsPerFoot
        if (lenFeet < minFeet) {
            drawing.active = false
            return
        }
        const shape = makeShape(
            drawing.type,
            drawing.startX,
            drawing.startY,
            drawing.currentX,
            drawing.currentY
        )
        if (!shape) return
        pushUndoState()
        shapes.push(shape)
        selected = shapes.length - 1
    }

    function hitTestShapes(p) {
        let hit = -1
        let best = pickTolerancePixels / (pixelsPerFoot * zoom)  // zoom-aware selection
        for (let i = 0; i < shapes.length; i++) {
            const s = shapes[i]
            // endpoint tolerance in world units (screen pixels converted)
            const endpointTolFeet = 8 / (pixelsPerFoot * zoom)
            const nearEndpoint =
                distanceToPoint(p.x, p.y, s.x1, s.y1) < endpointTolFeet ||
                distanceToPoint(p.x, p.y, s.x2, s.y2) < endpointTolFeet
            // skip endpoints only if needed (resizing)
            if (nearEndpoint) continue
            const d = distancePointToSegment(p.x, p.y, s.x1, s.y1, s.x2, s.y2)
            if (d < best) {
                best = d
                hit = i
            }
        }
        return hit
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
                const g = shapeGeometry(s)
                if (!g) return
                if (s.type == "wall") {
                    drawWallRect(ctx, g)
                } else if (s.type == "door") {
                    drawDoor(ctx, s)
                } else if (s.type == "dimension") {
                    drawDimension(ctx, s.x1, s.y1, s.x2, s.y2)
                } else if (s.type == "window") {
                    drawWindowRect(ctx, g, false)
                }
                if (i === selected) {
                    annotateShape(ctx, g, s)
                }
            })
            drawPreviews(ctx)
            ctx.restore()
        }
    }

MouseArea {
    property real lastX
    property real lastY
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton|Qt.RightButton

    function getMouseWorldPos(mouse) {
        return screenToWorld(mouse.x, mouse.y)
    }

    function isLeftButton(mouse) { return mouse.button === Qt.LeftButton }
    function isLeftPressed(mouse) { return mouse.buttons & Qt.LeftButton }
    function isRightPressed(mouse) { return mouse.buttons & Qt.RightButton }

    onPressed: mouse => {
        root.forceActiveFocus()

        if (isLeftButton(mouse)) {
            const p = getMouseWorldPos(mouse)
            // Drawing shortcuts
            if (mouse.modifiers & Qt.AltModifier) return startDrawing("window", mouse)
            if (mouse.modifiers & Qt.ControlModifier) return startDrawing("door", mouse)
            if (mouse.modifiers & Qt.ShiftModifier) return startDrawing("dimension", mouse, true)

            if (selected !== -1) {
                const s = shapes[selected]
                // Resize handle
                const end = hitWallEndpoint(p, s)
                if (end !== 0) {
                    pushUndoState()
                    resizing = true
                    resizeEnd = end
                    return
                }
                // Rotate handle
                if (hitRotateHandle(p, s)) {
                    pushUndoState()
                    rotating = true
                    rotateBaseAngle = shapeAngle(s)
                    const center = shapeCenter(s)
                    rotateStartAngle = Math.atan2(p.y - center.y, p.x - center.x)
                    return
                }
            }
            // Selection / new wall
            const hit = hitTestShapes(p)
            if (hit !== -1) {
                selected = hit
                pushUndoState()
                dragging = true
                dragStartX = p.x
                dragStartY = p.y
                const s = shapes[selected]
                dragOrigShape = { x1: s.x1, y1: s.y1, x2: s.x2, y2: s.y2 }
                drawing.active = false
            } else {
                selected = -1
                startDrawing("wall", mouse)
            }
            canvas.requestPaint()
            return
        }
        // Right button pan
        lastX = mouse.x
        lastY = mouse.y
    }

    onPositionChanged: mouse => {
        const p = getMouseWorldPos(mouse)
        if (drawing.active && isLeftPressed(mouse)) {
            drawing.currentX = p.x
            drawing.currentY = p.y
        } else if (resizing && isLeftPressed(mouse)) {
            const s = shapes[selected]
            if (resizeEnd === 1) { s.x1 = p.x; s.y1 = p.y } 
            else { s.x2 = p.x; s.y2 = p.y }
        } else if (rotating && isLeftPressed(mouse)) {
            const s = shapes[selected]
            const center = shapeCenter(s)
            const angle = Math.atan2(p.y - center.y, p.x - center.x)
            rotateShape(s, rotateBaseAngle + (angle - rotateStartAngle))
        } else if (dragging && isLeftPressed(mouse)) {
            const dx = p.x - dragStartX
            const dy = p.y - dragStartY
            const s = shapes[selected]
            s.x1 = dragOrigShape.x1 + dx
            s.y1 = dragOrigShape.y1 + dy
            s.x2 = dragOrigShape.x2 + dx
            s.y2 = dragOrigShape.y2 + dy
        } else if (isRightPressed(mouse)) {
            offsetX += mouse.x - lastX
            offsetY += mouse.y - lastY
            lastX = mouse.x
            lastY = mouse.y
        } else return // Nothing changed

        canvas.requestPaint()
    }

    onReleased: mouse => {
        if (drawing.active && isLeftButton(mouse)) {
            finishDrawing()        // commits the new shape
            drawing.active = false
            canvas.requestPaint()
            return
        }
        if (resizing) {
            pushUndoState()        // commit resize
            resizing = false
            resizeEnd = 0
            canvas.requestPaint()
        }
        if (rotating) {
            pushUndoState()        // commit rotation
            rotating = false
            canvas.requestPaint()
        }
        if (dragging) {
            pushUndoState()        // commit drag
            dragging = false
            dragOrigShape = null
            canvas.requestPaint()
        }
    }

    onWheel: wheel => {
        const factor = wheel.angleDelta.y > 0 ? 1.1 : 0.9
        zoom = Math.max(0.2, Math.min(5, zoom * factor))
        canvas.requestPaint()
    }

    onDoubleClicked: mouse => {
        const p = getMouseWorldPos(mouse)
        const hit = hitTestShapes(p)
        if (hit !== -1) {
            selected = hit
            editor.showEditor(shapes[hit], hit)
        }
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