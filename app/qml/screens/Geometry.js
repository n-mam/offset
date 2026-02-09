
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
