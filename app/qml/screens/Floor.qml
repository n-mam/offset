import QtQuick
import QtQuick.Dialogs
import Qt.labs.platform
import "qrc:/components"
import "qrc:/screens/Shape.js" as Shape
import "qrc:/screens/Geometry.js" as Geo

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
    property real offsetX: 0
    property real offsetY: 0
    property real pixelsPerFoot: 30

    property var shapes: []

    property int selected: -1
    property real minDrawPixels: 6   // 4–8 px feels good
    property real pickTolerancePixels: 8 // feels good: 6–10 px

    property bool rotating: false
    property real rotateStartAngle: 0
    property real rotateBaseAngle: 0

    property real moveStepFeet: 0.0416667 // ~0.5 inches
    property real moveStepFastFeet: 0.1  // 1.2 inches when Shift is held

    property url lastSaveUrl
    property bool resizing: false
    property int resizeEnd: 0   // 1 = x1/y1, 2 = x2/y2
    property string fileDialogMode: "save" // or "load"

    property bool dragging: false
    property real dragStartX: 0
    property real dragStartY: 0
    property var dragOrigShape: null

    PropertyEditor {
        id: editor
    }

    ShapeSelector {
        id: shapeSelector
    }

    FileDialog {
        id: fileDialog
        title: fileDialogMode === "save"
            ? "Save Floor Plan"
            : "Load Floor Plan"
        fileMode: fileDialogMode === "save"
            ? FileDialog.SaveFile
            : FileDialog.OpenFile
        nameFilters: [ "All Files (*)" ]
        onAccepted: handleFileDialogAccepted(this, fileDialogMode)
        folder: StandardPaths.writableLocation(StandardPaths.DesktopLocation)
    }

    property var drawing: ({
        type: "",
        active: false,
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0,
        thickness: 0.5
    })

    property var gridLevels: [
        { step: 0.25, color: "#3a3a3a", width: 0.5 },
        { step: 1,    color: "#505050", width: 1   },
        { step: 5,    color: "#707070", width: 2   }
    ]

    property var colors: ({
        white: "#ffffff",
        wallFill: "#dcd0aa",
        wallOutline: "rgba(120,95,60,0.6)",
        hatchStroke: "rgba(140,110,70,0.6)",
        selected: "#ff0000",
        preview: "#00ff88",
        rotateHandle: "#00aaff",
        resizeStart: "#00b45d", // start point (green)
        resizeEnd: "#ff3131"    // end point (orange)
    })

    function resolveTool(mouse) {
        if (mouse.modifiers & Qt.AltModifier) {
            shapeSelector.currentTool = "window"
            return "window"
        }
        if (mouse.modifiers & Qt.ControlModifier) {
            shapeSelector.currentTool = "door"
            return "door"
        }
        if (mouse.modifiers & Qt.ShiftModifier) {
            shapeSelector.currentTool = "dimension"
            return "dimension"
        }
        return shapeSelector.currentTool
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
        ctx.fillStyle = "rgba(174, 174, 174, 0.5)"
        ctx.fill();
        // BLUE WINDOW BORDER (perimeter)
        polygonPath(ctx, g.corners);
        ctx.lineWidth = 1 / zoom;
        ctx.strokeStyle = "#000000";
        ctx.stroke();
        // centerline
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
        //hatch
        ctx.save()
        polygonPath(ctx, g.corners)
        ctx.clip()
        const spacing = 6 / zoom
        const wallAngle = Math.atan2(g.ty, g.tx)
        const hatchAngle = wallAngle + Math.PI / 4
        // bounding box (you already computed these)
        const xs = g.corners.map(c => c.x)
        const ys = g.corners.map(c => c.y)
        const minX = Math.min.apply(null, xs)
        const maxX = Math.max.apply(null, xs)
        const minY = Math.min.apply(null, ys)
        const maxY = Math.max.apply(null, ys)
        // center of the wall area
        const cx = (minX + maxX) * 0.5
        const cy = (minY + maxY) * 0.5
        ctx.translate(cx, cy)
        ctx.rotate(hatchAngle)
        ctx.strokeStyle = colors.hatchStroke
        ctx.lineWidth = 1 / zoom
        // long enough to cover any rotation
        const L = Math.max(maxX - minX, maxY - minY) * 2
        for (let y = -L; y <= L; y += spacing) {
            ctx.beginPath()
            ctx.moveTo(-L, y)
            ctx.lineTo(L, y)
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
        ctx.lineWidth = door.thickness * pixelsPerFoot;
        ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
        // TOP-LEFT radial edge (1px white)
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

    function hitRotateHandle(p, w) {
        const c = Shape.center(w)
        const angle = Shape.angle(w)
        // convert pixel distance → feet
        const handleDistFeet = (20 / zoom) / pixelsPerFoot
        const radiusFeet = (8 / zoom) / pixelsPerFoot
        const hx = c.x + Math.cos(angle + Math.PI / 2) * handleDistFeet
        const hy = c.y + Math.sin(angle + Math.PI / 2) * handleDistFeet
        return Geo.distanceToPoint(p.x, p.y, hx, hy) < radiusFeet
    }

    function hitWallEndpoint(p, w) {
        const tolFeet = (8 / zoom) / pixelsPerFoot
        if (Geo.distanceToPoint(p.x, p.y, w.x1, w.y1) < tolFeet)
            return 1
        if (Geo.distanceToPoint(p.x, p.y, w.x2, w.y2) < tolFeet)
            return 2
        return 0
    }

    function wallAngleForDisplay(w) {
        const dx = w.x2 - w.x1
        const dy = w.y2 - w.y1
        return Math.atan2(-dy, dx)
    }

    function buildAllWallPath(ctx) {
        ctx.beginPath()
        shapes.forEach(s => {
            if (s.type !== "wall") return
            const g = Shape.geometry(s, pixelsPerFoot)
            if (!g) return
            ctx.moveTo(g.corners[0].x, g.corners[0].y)
            for (let i = 1; i < g.corners.length; i++)
                ctx.lineTo(g.corners[i].x, g.corners[i].y)
            ctx.closePath()
        })
    }

    function drawGrid(ctx) {
        const left   = (-offsetX) / (zoom * pixelsPerFoot)
        const right  = (canvas.width - offsetX) / (zoom * pixelsPerFoot)
        const top    = (-offsetY) / (zoom * pixelsPerFoot)
        const bottom = (canvas.height - offsetY) / (zoom * pixelsPerFoot)
        const labelTop  = (-offsetY) / zoom
        const labelLeft = (-offsetX) / zoom
        gridLevels.forEach(level => {
            const stepFeet = level.step

            ctx.strokeStyle = level.color
            ctx.lineWidth = level.width / zoom

            const startX = Math.floor(left / stepFeet) * stepFeet
            const endX   = Math.ceil(right / stepFeet) * stepFeet
            const startY = Math.floor(top / stepFeet) * stepFeet
            const endY   = Math.ceil(bottom / stepFeet) * stepFeet

            // Vertical lines
            for (let x = startX; x <= endX; x += stepFeet) {
                const cx = x * pixelsPerFoot
                ctx.beginPath()
                ctx.moveTo(cx, top * pixelsPerFoot)
                ctx.lineTo(cx, bottom * pixelsPerFoot)
                ctx.stroke()
            }

            // Horizontal lines
            for (let y = startY; y <= endY; y += stepFeet) {
                const cy = y * pixelsPerFoot
                ctx.beginPath()
                ctx.moveTo(left * pixelsPerFoot, cy)
                ctx.lineTo(right * pixelsPerFoot, cy)
                ctx.stroke()
            }
            // Major labels
            if (stepFeet === 5) {
                ctx.fillStyle = "#ffffff"
                ctx.font = `${12 / zoom}px sans-serif`
                for (let x = startX; x <= endX; x += stepFeet) {
                    if (x !== 0)
                        ctx.fillText(
                            Math.round(x),
                            x * pixelsPerFoot + 2 / zoom,
                            labelTop + 12 / zoom
                        )
                }
                for (let y = startY; y <= endY; y += stepFeet) {
                    if (y !== 0)
                        ctx.fillText(
                            Math.round(y),
                            labelLeft + 2 / zoom,
                            y * pixelsPerFoot - 2 / zoom
                        )
                }
            }
            // 3-inch labels
            if (stepFeet === 0.25 && zoom >= 2.5) {
                ctx.fillStyle = "#bbbbbb"
                ctx.font = `${10 / zoom}px sans-serif`
                for (let x = startX; x <= endX; x += stepFeet) {
                    const inches = Math.round(x * 12)
                    if (inches % 3 === 0 && inches !== 0)
                        ctx.fillText(
                            `${inches}"`,
                            x * pixelsPerFoot + 2 / zoom,
                            labelTop + 10 / zoom
                        )
                }
                for (let y = startY; y <= endY; y += stepFeet) {
                    const inches = Math.round(y * 12)
                    if (inches % 3 === 0 && inches !== 0)
                        ctx.fillText(
                            `${inches}"`,
                            labelLeft + 2 / zoom,
                            y * pixelsPerFoot - 2 / zoom
                        )
                }
            }
        })
        // Origin
        ctx.fillStyle = "#ffffff"
        ctx.beginPath()
        ctx.arc(0, 0, 4 / zoom, 0, Math.PI * 2)
        ctx.fill()
    }

    function drawWallLengthLabel(ctx, s) {
        // World → pixel
        const x1 = s.x1 * pixelsPerFoot
        const y1 = s.y1 * pixelsPerFoot
        const x2 = s.x2 * pixelsPerFoot
        const y2 = s.y2 * pixelsPerFoot

        const dx = x2 - x1
        const dy = y2 - y1
        const len = Math.hypot(dx, dy)
        if (len < 1e-6) return

        // Midpoint (pixel space)
        const mx = (x1 + x2) * 0.5
        const my = (y1 + y2) * 0.5

        // Perpendicular unit normal
        let nx = -dy / len
        let ny = dx / len

        // Force "top" (screen-up = negative Y)
        if (ny > 0) {
            nx = -nx
            ny = -ny
        }

        // Wall half thickness + padding
        const wallHalfPx = (s.thickness * pixelsPerFoot) / 2
        const paddingPx = 6 / zoom

        const px = mx + nx * (wallHalfPx + paddingPx)
        const py = my + ny * (wallHalfPx + paddingPx)

        // Screen space
        const p = Geo.canvasToScreen({ x: px, y: py })

        // Label text
        const lengthFeet = Math.hypot(s.x2 - s.x1, s.y2 - s.y1)
        const label = Geo.formatFeetInches(lengthFeet)

        ctx.save()
        ctx.setTransform(1, 0, 0, 1, 0, 0)
        ctx.font = "12px sans-serif"
        ctx.fillStyle = "#ffffff"
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
        const angle = Shape.angle(s)
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
        ctx.fillStyle = colors.resizeStart
        ctx.fill()
        ctx.beginPath()
        ctx.arc(g.x2, g.y2, 5 / zoom, 0, Math.PI * 2)
        ctx.fillStyle = colors.resizeEnd
        ctx.fill()
        drawWallLengthLabel(ctx, s)
        // angle visualizer while rotating
        if (rotating) {
            const c = Shape.center(s)
            const a = wallAngleForDisplay(s)
            const cx = c.x * pixelsPerFoot
            const cy = c.y * pixelsPerFoot
            drawAngleVisualizer(ctx, cx, cy, a, zoom)
        }
    }

    function drawPreviews(ctx) {
        if (!drawing.active) return
        const shape = Shape.make(
            drawing.type,
            drawing.startX,
            drawing.startY,
            drawing.currentX,
            drawing.currentY,
            drawing.thickness)
        if (!shape) return
        if (shape.type === "wall") {
            const g = Shape.geometry(shape, pixelsPerFoot)
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
            drawWallLengthLabel(ctx, shape)
            const dx = shape.x2 - shape.x1
            const dy = shape.y2 - shape.y1
            drawAngleVisualizer(ctx, g.x1, g.y1, -Math.atan2(dy, dx), zoom)
        }
        else if (shape.type === "window") {
            const g = Shape.geometry(shape, pixelsPerFoot)
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

    function drawDimension(ctx, x1Feet, y1Feet, x2Feet, y2Feet, barSizePx = 4) {
        // world (feet) → canvas (pixels)
        const x1 = x1Feet * pixelsPerFoot;
        const y1 = y1Feet * pixelsPerFoot;
        const x2 = x2Feet * pixelsPerFoot;
        const y2 = y2Feet * pixelsPerFoot;
        // Vector from start → end
        const dx = x2 - x1;
        const dy = y2 - y1;
        const length = Math.hypot(dx, dy) || 1; // prevent divide-by-zero
        const isVertical = Math.abs(dy) > Math.abs(dx);
        // Main line
        ctx.strokeStyle = colors.white;
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
        const label = Geo.formatFeetInches(lengthFeet);
        // Midpoint
        const mx = (x1 + x2) / 2;
        const my = (y1 + y2) / 2;
        // Perpendicular offset for label
        const labelOffsetPx = 14 / zoom;
        const ox = (dy / length) * labelOffsetPx;
        const oy = (-dx / length) * labelOffsetPx;
        // Convert midpoint + offset to screen space
        const p = Geo.canvasToScreen({ x: mx + ox, y: my + oy });
        // Draw label
        ctx.save()
        // reset to screen space
        ctx.setTransform(1, 0, 0, 1, 0, 0)
        // move origin to label position
        ctx.translate(p.x, p.y)
        // rotate if vertical
        if (isVertical) {
            // keep text readable (not upside down)
            const angle = dy > 0 ? Math.PI / 2 : -Math.PI / 2
            ctx.rotate(angle)
        }
        ctx.fillStyle = colors.white
        ctx.font = "12px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        // draw at origin
        ctx.fillText(label, 0, 0)
        ctx.restore()
    }

    function startDrawing(type, mouse, pushUndo = false) {
        if (pushUndo) pushUndoState()
        const p = Geo.screenToWorld(mouse.x, mouse.y)
        drawing.type = type
        drawing.active = true
        drawing.startX = p.x
        drawing.startY = p.y
        drawing.currentX = p.x
        drawing.currentY = p.y
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
        const shape = Shape.make(
            drawing.type,
            drawing.startX,
            drawing.startY,
            drawing.currentX,
            drawing.currentY,
            drawing.thickness
        )
        if (!shape) return
        pushUndoState()
        shapes.push(shape)
        selected = shapes.length - 1
    }

    function saveProject() {
        if (lastSaveUrl && lastSaveUrl.toString().length > 0) {
            floorManager.saveToFile(lastSaveUrl, Shape.serializeProject(shapes, pixelsPerFoot))
        } else {
            fileDialogMode = "save"
            fileDialog.open()
        }
    }

    function handleFileDialogAccepted(dialog, mode) {
        const path = dialog.currentFile
        if (mode === "save") {
            lastSaveUrl = path
            floorManager.saveToFile(path, Shape.serializeProject())
        } else if (mode === "load") {
            const json = floorManager.loadFromFile(path)
            if (json) {
                lastSaveUrl = path
                const result = Shape.deserializeProject(json)
                pixelsPerFoot = result.pixelsPerFoot ?? pixelsPerFoot
                shapes = result.shapes
                Qt.callLater(() => {
                    fitDrawingToView()
                    canvas.requestPaint()
                })                
            } else {
                console.warn("Failed to load project file")
            }
        }
    }

    function fitDrawingToView(paddingPx = 40) {
        if (!shapes || shapes.length === 0) return
        let minX = Infinity, minY = Infinity
        let maxX = -Infinity, maxY = -Infinity
        shapes.forEach(s => {
            minX = Math.min(minX, s.x1, s.x2)
            minY = Math.min(minY, s.y1, s.y2)
            maxX = Math.max(maxX, s.x1, s.x2)
            maxY = Math.max(maxY, s.y1, s.y2)
            if (s.thickness) {
                const pad = s.thickness * 0.5
                minX -= pad
                minY -= pad
                maxX += pad
                maxY += pad
            }
        })
        // size in world units (feet)
        const widthFeet  = Math.max(1e-6, maxX - minX)
        const heightFeet = Math.max(1e-6, maxY - minY)
        // convert to pixels
        const widthPx  = widthFeet  * pixelsPerFoot
        const heightPx = heightFeet * pixelsPerFoot
        // choose zoom to fit viewport
        const zx = (canvas.width  - paddingPx * 2) / widthPx
        const zy = (canvas.height - paddingPx * 2) / heightPx
        zoom = Math.max(0.2, Math.min(5, Math.min(zx, zy)))
        // center of drawing
        const cxFeet = (minX + maxX) * 0.5
        const cyFeet = (minY + maxY) * 0.5
        offsetX = canvas.width  * 0.5 - cxFeet * pixelsPerFoot * zoom
        offsetY = canvas.height * 0.5 - cyFeet * pixelsPerFoot * zoom
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
            // fill all walls once
            ctx.save()
            buildAllWallPath(ctx)
            ctx.fillStyle = colors.wallFill
            ctx.fill("evenodd")
            ctx.restore()
            // draw per-shape details
            shapes.forEach((s, i) => {
                const g = Shape.geometry(s, pixelsPerFoot)
                if (!g) return
                if (s.type === "door") {
                    drawDoor(ctx, s)
                } else if (s.type === "dimension") {
                    drawDimension(ctx, s.x1, s.y1, s.x2, s.y2)
                } else if (s.type === "window") {
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
            return Geo.screenToWorld(mouse.x, mouse.y)
        }

        function isLeftButton(mouse) { return mouse.button === Qt.LeftButton }
        function isLeftPressed(mouse) { return mouse.buttons & Qt.LeftButton }
        function isRightPressed(mouse) { return mouse.buttons & Qt.RightButton }

        onPressed: mouse => {
            root.forceActiveFocus()

            if (isLeftButton(mouse)) {
                const p = getMouseWorldPos(mouse)
                if (selected !== -1) {
                    const s = shapes[selected]
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
                        rotateBaseAngle = Shape.angle(s)
                        const center = Shape.center(s)
                        rotateStartAngle = Math.atan2(p.y - center.y, p.x - center.x)
                        return
                    }
                }
                // Selection / new wall
                const hit = Shape.hitTest(
                    p,
                    shapes,
                    pixelsPerFoot,
                    zoom,
                    pickTolerancePixels)
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
                    const tool = resolveTool(mouse)
                    const pushUndo = (tool === "dimension")
                    selected = -1
                    startDrawing(tool, mouse, pushUndo)
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
                const center = Shape.center(s)
                const angle = Math.atan2(p.y - center.y, p.x - center.x)
                Shape.rotate(s, rotateBaseAngle + (angle - rotateStartAngle))
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
            const hit = Shape.hitTest(
                p,
                shapes,
                pixelsPerFoot,
                zoom,
                pickTolerancePixels)
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
            case Qt.Key_S:
                if (event.modifiers & Qt.ControlModifier) {
                    saveProject()
                    event.accepted = true
                }
                break
            case Qt.Key_L:
                if (event.modifiers & Qt.ControlModifier) {
                    fileDialogMode = "load"
                    fileDialog.open()
                    event.accepted = true
                }
                break
            case Qt.Key_F:
                if (event.modifiers & Qt.ControlModifier) {
                    fitDrawingToView()
                    canvas.requestPaint()
                    event.accepted = true
                }
                break
        }
    }
    Component.onCompleted: {
        shapeSelector.open()
    }
}