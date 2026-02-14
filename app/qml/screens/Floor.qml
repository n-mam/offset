import QtQuick
import QtQuick.Dialogs
import Qt.labs.platform
import "qrc:/components"
import "qrc:/screens/Shape.js" as Shape
import "qrc:/screens/Drawing.js" as Draw
import "qrc:/screens/Geometry.js" as Geometry

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
    property real pixelsPerFoot: 52

    property var shapes: []

    property int selected: -1
    property url lastSaveUrl
    property real minDrawPixels: 6   // 4–8 px feels good
    property real pickTolerancePixels: 8 // feels good: 6–10 px

    property real moveStepFeet: 0.0416667 // ~0.5 inches
    property real moveStepFastFeet: 0.1  // 1.2 inches when Shift is held
    property int resizeEnd: 0   // 1 = x1/y1, 2 = x2/y2
    property string fileDialogMode: "save" // or "load"

    property bool panning: false
    property bool rotating: false
    property bool dragging: false
    property bool resizing: false

    property real dragStartX: 0
    property real dragStartY: 0
    property var dragOrigShape: null
    property real rotateBaseAngle: 0
    property real rotateStartAngle: 0

    PropertyEditor { 
        id: editor
        onTransformRequested: (direction, mode) => {
            if (selected === -1) return;
            var s = shapes[selected];          
            if (mode === "move") {
                Draw.moveShape(s, direction)
            } else if (mode === "snap") {
                Draw.snapShape(s, direction)
            }
        }        
    }
    ShapeSelector { id: shapeSelector }

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
        startX: 0,
        startY: 0,
        currentX: 0,
        currentY: 0,
        thickness: 1,
        active: false
    })

    property var gridLevels: [
        //{ step: 0.25, color: "#3a3a3a", width: 0.5 },
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

    function pushUndoState() {
        if (undoStack.length >= maxUndoSteps)
            undoStack.shift()
        undoStack.push({
            shapes: shapes.map(s => Object.assign({}, s)),
        })
    }

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

    function hitRotateHandle(p, w) {
        const c = Shape.center(w)
        const angle = Shape.angle(w)
        // convert pixel distance → feet
        const handleDistFeet = (20 / zoom) / pixelsPerFoot
        const radiusFeet = (8 / zoom) / pixelsPerFoot
        const hx = c.x + Math.cos(angle + Math.PI / 2) * handleDistFeet
        const hy = c.y + Math.sin(angle + Math.PI / 2) * handleDistFeet
        return Geometry.distanceToPoint(p.x, p.y, hx, hy) < radiusFeet
    }

    function hitWallEndpoint(p, w) {
        const tolFeet = (8 / zoom) / pixelsPerFoot
        if (Geometry.distanceToPoint(p.x, p.y, w.x1, w.y1) < tolFeet)
            return 1
        if (Geometry.distanceToPoint(p.x, p.y, w.x2, w.y2) < tolFeet)
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
        if (s.type !== "dimension") {
            Draw.lengthLabel(ctx, s)
        }
        // angle visualizer while rotating
        if (rotating) {
            const c = Shape.center(s)
            const a = wallAngleForDisplay(s)
            const cx = c.x * pixelsPerFoot
            const cy = c.y * pixelsPerFoot
            Draw.angleVisualizer(ctx, cx, cy, a, zoom)
        }
    }

    function startDrawing(type, mouse, pushUndo = false) {
        if (pushUndo) pushUndoState()
        const p = Geometry.screenToWorld(mouse.x, mouse.y)
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
            floorManager.saveToFile(path, Shape.serializeProject(shapes, pixelsPerFoot))
        } else if (mode === "load") {
            const json = floorManager.loadFromFile(path)
            if (json) {
                lastSaveUrl = path
                const result = Shape.deserializeProject(json)
                pixelsPerFoot = result.pixelsPerFoot ?? pixelsPerFoot
                shapes = result.shapes
                undoStack = []
                selected = -1
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
            Draw.grid(ctx)
            // fill all walls once individually so each can have its own color
            shapes.forEach(s => {
                if (s.type !== "wall") return
                const g = Shape.geometry(s, pixelsPerFoot)
                if (!g) return
                polygonPath(ctx, g.corners)
                ctx.fillStyle = s.color || colors.wallFill
                ctx.fill()
            })
            // draw per-shape details
            shapes.forEach((s, i) => {
                const g = Shape.geometry(s, pixelsPerFoot)
                if (!g) return
                if (s.type === "door") {
                    Draw.door(ctx, s)
                } else if (s.type === "dimension") {
                    Draw.dimension(ctx, s)
                } else if (s.type === "window") {
                    Draw.windowRect(ctx, g, s, false)
                }
                if (i === selected) {
                    annotateShape(ctx, g, s)
                }
            })
            Draw.previews(ctx)
            ctx.restore()
        }
    }

    MouseArea {
        property real lastX
        property real lastY
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton|Qt.RightButton

        function isLeftButton(mouse) { return mouse.button === Qt.LeftButton }
        function isLeftPressed(mouse) { return mouse.buttons & Qt.LeftButton }
        function isRightPressed(mouse) { return mouse.buttons & Qt.RightButton }

        onPressed: mouse => {
            root.forceActiveFocus()
            lastX = mouse.x
            lastY = mouse.y
            if (!isLeftButton(mouse)) return
            const p = Geometry.screenToWorld(mouse.x, mouse.y)
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
            // Selection / start drawing tool
            selected = -1
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
            } else if (shapeSelector.currentTool === "idle") {
                panning = true
                return
            } else {
                const tool = resolveTool(mouse)
                const pushUndo = (tool === "dimension")
                startDrawing(tool, mouse, pushUndo)
            }
            canvas.requestPaint()
        }

        onPositionChanged: mouse => {
            if (!isLeftPressed(mouse)) return
            const p = Geometry.screenToWorld(mouse.x, mouse.y)
            const s = selected !== -1 ? shapes[selected] : null
            if (drawing.active) {
                drawing.currentX = p.x
                drawing.currentY = p.y
            } else if (resizing && s) {
                if (resizeEnd === 1) {
                    s.x1 = p.x
                    s.y1 = p.y
                } else {
                    s.x2 = p.x
                    s.y2 = p.y
                }
            } else if (rotating && s) {
                const center = Shape.center(s)
                const angle = Math.atan2(p.y - center.y, p.x - center.x)
                Shape.rotate(s, rotateBaseAngle + (angle - rotateStartAngle))
            } else if (dragging && s) {
                const dx = p.x - dragStartX
                const dy = p.y - dragStartY
                s.x1 = dragOrigShape.x1 + dx
                s.y1 = dragOrigShape.y1 + dy
                s.x2 = dragOrigShape.x2 + dx
                s.y2 = dragOrigShape.y2 + dy
            } else if (panning) {
                offsetX += mouse.x - lastX
                offsetY += mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y
            } else {
                return
            }
            canvas.requestPaint()
        }

        onReleased: mouse => {
            if (panning) panning = false
            if (drawing.active) {
                finishDrawing()
                drawing.active = false
            }
            if (resizing) {
                pushUndoState();
                resizing = false;
                resizeEnd = 0
            }
            if (rotating) {
                pushUndoState();
                rotating = false
            }
            if (dragging) {
                pushUndoState();
                dragging = false;
                dragOrigShape = null
            }
            canvas.requestPaint()
        }

        onWheel: wheel => {
            const factor = wheel.angleDelta.y > 0 ? 1.1 : 0.9
            // Mouse position in screen space
            const mx = wheel.x
            const my = wheel.y
            // World position under mouse BEFORE zoom
            const wx = (mx - offsetX) / zoom
            const wy = (my - offsetY) / zoom
            // Apply zoom (clamped)
            const newZoom = Math.max(0.2, Math.min(5, zoom * factor))
            if (newZoom === zoom) return
            zoom = newZoom
            // Recompute offset so mouse stays fixed
            offsetX = mx - wx * zoom
            offsetY = my - wy * zoom
            canvas.requestPaint()
        }

        onDoubleClicked: mouse => {
            const p = Geometry.screenToWorld(mouse.x, mouse.y)
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
        var s = shapes[selected]
        switch (event.key) {
            case Qt.Key_Left:
                if (selected === -1) break
                Draw.moveShape(s, "left", step)
                break
            case Qt.Key_Right:
                if (selected === -1) break
                Draw.moveShape(s, "right", step)
                break
            case Qt.Key_Up:
                if (selected === -1) break
                Draw.moveShape(s, "up", step)
                break
            case Qt.Key_Down:
                if (selected === -1) break
                Draw.moveShape(s, "down", step)
                break
            case Qt.Key_Z:
                if (event.modifiers & Qt.ControlModifier) {
                    if (undoStack.length > 0) {
                        const state = undoStack.pop()
                        shapes = state.shapes
                        selected = -1
                        canvas.requestPaint()
                    }
                }
                break
            case Qt.Key_S:
                if (event.modifiers & Qt.ControlModifier) {
                    saveProject()
                }
                break
            case Qt.Key_L:
                if (event.modifiers & Qt.ControlModifier) {
                    fileDialogMode = "load"
                    fileDialog.open()
                }
                break
            case Qt.Key_F:
                if (event.modifiers & Qt.ControlModifier) {
                    fitDrawingToView()
                    canvas.requestPaint()
                }
                break
            case Qt.Key_H:
                if (selected === -1) break
                if (event.modifiers & Qt.ControlModifier) {
                    Draw.makeHorizontal(s)
                }
                break
            case Qt.Key_V:
                if (selected === -1) break
                if (event.modifiers & Qt.ControlModifier) {
                    Draw.makeVertical(s)
                }
                break
        }
        event.accepted = true
    }

    Component.onCompleted: {
        shapeSelector.open()
    }
}