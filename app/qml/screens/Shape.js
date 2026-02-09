    function uid() {
        return "e" + Math.random().toString(36).slice(2, 9)
    }

    function geometry(s) {
        let x1, y1, x2, y2, thicknessFeet;
        switch(s.type) {
            case "wall":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                thicknessFeet = s.thickness;
                break;
            case "door":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                // approximate thickness as the "door leaf width" (feet)
                thicknessFeet = s.thickness
                break;
            case "window":
                x1 = s.x1; y1 = s.y1;
                x2 = s.x2; y2 = s.y2;
                thicknessFeet = s.thickness;
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
        const len = Geo.distanceToPoint(w.x2, w.y2, w.x1, w.y1) / 2
        w.x1 = c.x - Math.cos(angleRad) * len
        w.y1 = c.y - Math.sin(angleRad) * len
        w.x2 = c.x + Math.cos(angleRad) * len
        w.y2 = c.y + Math.sin(angleRad) * len
    }

    function hitTest(p) {
        let hit = -1
        let best = pickTolerancePixels / (pixelsPerFoot * zoom)  // zoom-aware selection
        for (let i = 0; i < shapes.length; i++) {
            const s = shapes[i]
            // endpoint tolerance in world units (screen pixels converted)
            const endpointTolFeet = 8 / (pixelsPerFoot * zoom)
            const nearEndpoint =
                Geo.distanceToPoint(p.x, p.y, s.x1, s.y1) < endpointTolFeet ||
                Geo.distanceToPoint(p.x, p.y, s.x2, s.y2) < endpointTolFeet
            // skip endpoints only if needed (resizing)
            if (nearEndpoint) continue
            const d = Geo.distancePointToSegment(p.x, p.y, s.x1, s.y1, s.x2, s.y2)
            if (d < best) {
                best = d
                hit = i
            }
        }
        return hit
    }

    function make(type, startX, startY, endX, endY, thickness) {
        const dx = endX - startX
        const dy = endY - startY
        const len = Math.hypot(dx, dy)
        if (len === 0) return null
        const base = {
            id: uid(),
            x1: startX,
            y1: startY,
            x2: endX,
            y2: endY,
            thickness: thickness
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

    function serializeProject() {
        return JSON.stringify({
            format: "FloorPlanProject",
            version: 1,
            units: { length: "feet" },
            settings: {
                pixelsPerUnit: pixelsPerFoot
            },
            entities: shapes.map(s => ({
                id: s.id,
                type: s.type,
                geometry: {
                    x1: s.x1,
                    y1: s.y1,
                    x2: s.x2,
                    y2: s.y2
                },
                properties: {
                    thickness: s.thickness
                }
            })),
            meta: {
                created: new Date().toISOString(),
                modified: new Date().toISOString()
            }
        }, null, 2)
    }

    function deserializeProject(jsonText, path) {
        const doc = JSON.parse(jsonText)
        if (doc.format !== "FloorPlanProject")
            throw "Not a floor plan project"
        if (doc.version > 1)
            throw "Project version too new"
        pixelsPerFoot =
            doc.settings?.pixelsPerUnit ?? pixelsPerFoot
        shapes = doc.entities.map(e => ({
            id: e.id,
            type: e.type,
            x1: e.geometry.x1,
            y1: e.geometry.y1,
            x2: e.geometry.x2,
            y2: e.geometry.y2,
            thickness: e.properties?.thickness ?? 0.5
        }))
        // reset transient editor state
        undoStack = []
        selected = -1
        drawing.active = false
        canvas.requestPaint()
    }
