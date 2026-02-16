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

    switch (s.type) {
        case "door": {
            // hinge is always x1,y1
            if (horizontal) {
                s.x2 = 2 * s.x1 - s.x2; // mirror leaf across hinge X
            } else {
                s.y2 = 2 * s.y1 - s.y2; // mirror leaf across hinge Y
            }
            // recompute angle and width
            s.angle = Math.atan2(s.y2 - s.y1, s.x2 - s.x1);
            s.width = Math.hypot(s.x2 - s.x1, s.y2 - s.y1);
            break;
        }

        case "window": {
            // flip windows around center
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
            break;
        }

        default: {
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
            break;
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
        case "wall": return "#dcd0aa"
        case "window": return "#aeb0b0"
        case "door": return "#ffffff"
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
        entities: shapes.map(s => ({
            id: s.id,
            type: s.type,
            geometry: { x1: s.x1, y1: s.y1, x2: s.x2, y2: s.y2 },
            properties: {
                thickness: s.thickness,
                color: s.color ?? null
            }
        }))
    }, null, 2)
}

function deserializeProject(jsonText) {
    const doc = JSON.parse(jsonText)
    if (doc.format !== "FloorPlanProject")
        throw "Not a floor plan project"
    return {
        pixelsPerFoot: doc.settings?.pixelsPerUnit,
        shapes: doc.entities.map(e => ({
            id: e.id,
            type: e.type,
            x1: e.geometry.x1,
            y1: e.geometry.y1,
            x2: e.geometry.x2,
            y2: e.geometry.y2,
            thickness: e.properties?.thickness ?? 0.5,
            color: e.properties?.color ?? defaultColorForType(e.type)
        }))
    }
}
