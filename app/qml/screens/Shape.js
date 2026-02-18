.import "Geometry.js" as Geometry

function uid() {
    return "e" + Math.random().toString(36).slice(2, 9)
}

function geometry(s, pixelsPerFoot) {
    let x1, y1, x2, y2, thicknessFeet
    switch (s.type) {
        case "wall":
        case "window":
            x1 = s.x1; y1 = s.y1
            x2 = s.x2; y2 = s.y2
            thicknessFeet = s.thickness
            break
        case "door":
            x1 = s.x1; y1 = s.y1
            x2 = s.x2; y2 = s.y2
            thicknessFeet = s.thickness
            break
        case "dimension":
            x1 = s.x1; y1 = s.y1
            x2 = s.x2; y2 = s.y2
            thicknessFeet = s.thickness ?? 0
            break
        default:
            return null
    }

    const dx = x2 - x1
    const dy = y2 - y1
    const len = Math.hypot(dx, dy)
    if (len === 0) return null

    const tx = dx / len
    const ty = dy / len
    const nx = -ty
    const ny = tx

    const halfThicknessPx = (thicknessFeet / 2) * pixelsPerFoot
    const pxLen = len * pixelsPerFoot

    const x1Px = x1 * pixelsPerFoot
    const y1Px = y1 * pixelsPerFoot

    return {
        len,
        tx, ty,
        nx, ny,
        x1: x1Px,
        y1: y1Px,
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

function center(w) {
    return {
        x: (w.x1 + w.x2) / 2,
        y: (w.y1 + w.y2) / 2
    }
}

function angle(w) {
    return Math.atan2(w.y2 - w.y1, w.x2 - w.x1)
}

function rotate(w, angleRad) {
    const c = center(w)
    const halfLen = Geometry.distanceToPoint(w.x2, w.y2, w.x1, w.y1) / 2
    w.x1 = c.x - Math.cos(angleRad) * halfLen
    w.y1 = c.y - Math.sin(angleRad) * halfLen
    w.x2 = c.x + Math.cos(angleRad) * halfLen
    w.y2 = c.y + Math.sin(angleRad) * halfLen
}

function flip(s, horizontal = true) {
    if (!s) return;
    if (s.type === "door") {
        if (horizontal) s.swing = !s.swing
    } else {
        // walls, dimensions: flip around center
        const cx = (s.x1 + s.x2) / 2;
        const cy = (s.y1 + s.y2) / 2;
        if (horizontal) {
            s.x1 = 2 * cx - s.x1;
            s.x2 = 2 * cx - s.x2;
        }
        if (!horizontal) {
            s.y1 = 2 * cy - s.y1;
            s.y2 = 2 * cy - s.y2;
        }
    }
    canvas.requestPaint();
}

function hitShapeEndpoint(p, w) {
    const tolFeet = (8 / zoom) / pixelsPerFoot
    if (Geometry.distanceToPoint(p.x, p.y, w.x1, w.y1) < tolFeet)
        return 1
    if (Geometry.distanceToPoint(p.x, p.y, w.x2, w.y2) < tolFeet)
        return 2
    return 0
}

function hitTest(p, shapes, pixelsPerFoot, zoom, pickTolerancePixels) {
    let hit = -1
    let best = pickTolerancePixels / (pixelsPerFoot * zoom)
    for (let i = 0; i < shapes.length; i++) {
        const s = shapes[i]
        const endpointTolFeet = 8 / (pixelsPerFoot * zoom)
        const nearEndpoint =
            Geometry.distanceToPoint(p.x, p.y, s.x1, s.y1) < endpointTolFeet ||
            Geometry.distanceToPoint(p.x, p.y, s.x2, s.y2) < endpointTolFeet

        if (nearEndpoint) continue
        const d = Geometry.distancePointToSegment(
            p.x, p.y,
            s.x1, s.y1,
            s.x2, s.y2
        )
        if (d < (best + (s.thickness / 4))) {
            best = d
            hit = i
        }
    }
    return hit
}

function make(type, startX, startY, endX, endY, thickness) {
    const dx = endX - startX
    const dy = endY - startY
    if (Math.hypot(dx, dy) === 0) return null
    const base = {
        id: uid(),
        x1: startX,
        y1: startY,
        x2: endX,
        y2: endY,
        thickness,
        swing: false,
        color: defaultColorForType(type).toString()
    }
    switch (type) {
        case "wall":
        case "door":
        case "window":
        case "dimension":
            return Object.assign({
                type,
                snap: { left: false, right: false, top: false, bottom: false }
            }, base)
        default:
            return null
    }
}

function defaultColorForType(type) {
    switch (type) {
        case "wall": return "#d2cab0"
        case "window": return "#aeb0b0"
        case "door": return "#c4a9a9a3"
        case "dimension": return "#ffffff"
        default: return "#ffffff"
    }
}

function serializeProject(shapes, pixelsPerFoot) {
    return JSON.stringify({
        format: "FloorPlanProject",
        version: 1,
        units: { length: "feet" },
        settings: { pixelsPerUnit: pixelsPerFoot },
        entities: shapes.map(function(s) {
            // Build snap data containing only TRUE flags
            var snapData = null
            if (s.snap) {
                var filtered = {}
                if (s.snap.left === true)
                    filtered.left = true
                if (s.snap.right === true)
                    filtered.right = true
                if (s.snap.top === true)
                    filtered.top = true
                if (s.snap.bottom === true)
                    filtered.bottom = true
                if (Object.keys(filtered).length > 0)
                    snapData = filtered
            }
            // Build entity object
            var entity = {
                id: s.id,
                type: s.type,
                geometry: {
                    x1: s.x1,
                    y1: s.y1,
                    x2: s.x2,
                    y2: s.y2
                },
                properties: {
                    thickness: s.thickness,
                    color: (s.color !== undefined ? s.color : null),
                    swing: s.swing === true
                }
            }
            // Only attach snap if at least one flag is true
            if (snapData !== null) {
                entity.properties.snap = snapData
            }
            return entity
        })
    }, null, 2)
}

function deserializeProject(jsonText) {
    var doc = JSON.parse(jsonText)
    if (doc.format !== "FloorPlanProject")
        throw "Not a floor plan project"
    return {
        pixelsPerFoot: (doc.settings && doc.settings.pixelsPerUnit)
                        ? doc.settings.pixelsPerUnit : undefined,
        shapes: doc.entities.map(function(e) {
            var props = e.properties ? e.properties : {}
            var savedSnap = props.snap ? props.snap : {}
            return {
                id: e.id,
                type: e.type,
                x1: e.geometry.x1,
                y1: e.geometry.y1,
                x2: e.geometry.x2,
                y2: e.geometry.y2,
                thickness: (props.thickness !== undefined) ? props.thickness : 0.5,
                color: (props.color !== undefined && props.color !== null) ?
                    props.color : defaultColorForType(e.type),
                swing: props.swing === true,
                snap: {
                    left: savedSnap.left === true,
                    right: savedSnap.right === true,
                    top: savedSnap.top === true,
                    bottom: savedSnap.bottom === true
                }
            }
        })
    }
}

function changeLength(s, length, anchor) {
    if (isNaN(length)) return
    const dx = s.x2 - s.x1;
    const dy = s.y2 - s.y1;
    const currentLength = Math.sqrt(dx * dx + dy * dy);
    // Prevent division by zero
    if (currentLength === 0) return;
    // Unit direction vector
    const ux = dx / currentLength;
    const uy = dy / currentLength;
    if (anchor === "S") {
        // Keep (x1, y1) fixed
        s.x2 = s.x1 + ux * length;
        s.y2 = s.y1 + uy * length;
    } else if (anchor === "E") {
        // Keep (x2, y2) fixed
        s.x1 = s.x2 - ux * length;
        s.y1 = s.y2 - uy * length;
    } else if (anchor === "C") {
        // Keep midpoint fixed
        const cx = (s.x1 + s.x2) / 2;
        const cy = (s.y1 + s.y2) / 2;
        const half = length / 2;
        s.x1 = cx - ux * half;
        s.y1 = cy - uy * half;
        s.x2 = cx + ux * half;
        s.y2 = cy + uy * half;
    }
    canvas.requestPaint();
}

function makeHorizontal(s, anchor) {
    const dx = s.x2 - s.x1;
    const dy = s.y2 - s.y1;
    const r = Math.sqrt(dx * dx + dy * dy);
    // rotation center
    let cx = (s.x1 + s.x2) / 2;
    let cy = (s.y1 + s.y2) / 2;
    if (anchor === "S") {
        cx = s.x1
        cy = s.y1
    } else if (anchor === "E") {
        cx = s.x2
        cy = s.y2
    }
    // Preserve original horizontal direction
    const dir = Math.sign(dx) || 1;
    const half = r / 2;
    if (anchor === "S") {
        s.x2 = cx + r * dir
        s.y2 = cy
    } else if (anchor === "C") {
        s.x1 = cx - dir * half;
        s.y1 = cy;
        s.x2 = cx + dir * half;
        s.y2 = cy;
    } else if (anchor === "E") {
        s.x1 = cx - r * dir
        s.y1 = cy
    }
    canvas.requestPaint();
}

function makeVertical(s, anchor) {
    const dx = s.x2 - s.x1;
    const dy = s.y2 - s.y1;
    const r = Math.sqrt(dx * dx + dy * dy);
    // rotation center
    let cx = (s.x1 + s.x2) / 2;
    let cy = (s.y1 + s.y2) / 2;
    if (anchor === "S") {
        cx = s.x1;
        cy = s.y1;
    } else if (anchor === "E") {
        cx = s.x2;
        cy = s.y2;
    }
    // Preserve original vertical direction
    const dir = Math.sign(dy) || 1;
    const half = r / 2;
    if (anchor === "S") {
        s.x2 = cx;
        s.y2 = cy + r * dir;
    } else if (anchor === "C") {
        s.x1 = cx;
        s.y1 = cy - dir * half;
        s.x2 = cx;
        s.y2 = cy + dir * half;
    } else if (anchor === "E") {
        s.x1 = cx;
        s.y1 = cy - r * dir;
    }
    canvas.requestPaint();
}

function move(s, direction, step = 0.25) {
    pushUndoState()
    let dxFeet, dyFeet
    switch (direction) {
        case "left": dxFeet = -step; dyFeet = 0; break;
        case "right": dxFeet = step; dyFeet = 0; break;
        case "up": dxFeet = 0; dyFeet = -step; break;
        case "down": dxFeet = 0; dyFeet = step; break;
    }
    s.x1 += dxFeet
    s.y1 += dyFeet
    s.x2 += dxFeet
    s.y2 += dyFeet
    // Moving cancels all constraints
    for (const key in s.snap) s.snap[key] = false;
    canvas.requestPaint()
}

function snapValue(v, grid) {
    var snapStepFeet = ((grid === "major") ? 5.0 : 1.0);
    return Math.round(v / snapStepFeet) * snapStepFeet
}

function snap(s, direction, grid) {
    pushUndoState();
    // Snap
    let isVertical = Math.abs(s.y1 - s.y2) > Math.abs(s.x1 - s.x2)
    let isHorizontal = Math.abs(s.x1 - s.x2) > Math.abs(s.y1 - s.y2)
    if (isVertical) makeVertical(s, "C")
    if (isHorizontal) makeHorizontal(s, "C")
    switch (direction) {
        case "left":
            if (isVertical) {
                let lface = snapValue(Math.min(s.x1, s.x2) - (s.thickness / 2), grid);
                s.x1 = s.x2 = lface + (s.thickness / 2)
            } else {
                let lface = snapValue(Math.min(s.x1, s.x2), grid);
                let delta = lface - Math.min(s.x1, s.x2)
                s.x1 += delta
                s.x2 += delta
            }
            s.snap.left = true;
            break;
        case "right":
            if (isVertical) {
                let rface = snapValue(Math.max(s.x1, s.x2) + (s.thickness / 2), grid);
                s.x1 = s.x2 = rface - (s.thickness / 2)
            } else {
                let rface = snapValue(Math.max(s.x1, s.x2), grid);
                let delta = rface - Math.max(s.x1, s.x2)
                s.x1 += delta
                s.x2 += delta
            }
            s.snap.right = true;
            break;
        case "up":
            if (isVertical) {
                let uface = snapValue(Math.min(s.y1, s.y2), grid);
                let delta = uface - Math.min(s.y1, s.y2)
                s.y1 += delta
                s.y2 += delta
            } else {
                let uface = snapValue(Math.min(s.y1, s.y2) - (s.thickness / 2), grid);
                let delta = uface - Math.min(s.y1, s.y2)
                s.y1 += delta + (s.thickness / 2)
                s.y2 += delta + (s.thickness / 2)
            }
            s.snap.top = true;
            break;
        case "down":
            if (isVertical) {
                let dface = snapValue(Math.max(s.y1, s.y2), grid);
                let delta = dface - Math.max(s.y1, s.y2)
                s.y1 += delta
                s.y2 += delta
            } else {
                let dface = snapValue(Math.max(s.y1, s.y2) + (s.thickness / 2), grid);
                let delta = dface - Math.max(s.y1, s.y2)
                s.y1 += delta - (s.thickness / 2)
                s.y2 += delta - (s.thickness / 2)
            }
            s.snap.bottom = true;
            break;
    }
    canvas.requestPaint();
}