function grid(ctx) {
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

function previews(ctx) {
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
        Draw.lengthLabel(ctx, shape)
        const dx = shape.x2 - shape.x1
        const dy = shape.y2 - shape.y1
        Draw.angleVisualizer(ctx, g.x1, g.y1, -Math.atan2(dy, dx), zoom)
    } else if (shape.type === "window") {
        const g = Shape.geometry(shape, pixelsPerFoot)
        if (!g) return
        ctx.save()
        ctx.globalAlpha = 0.6
        Draw.windowRect(ctx, g, shape, true)
        ctx.restore()
    } else if (shape.type === "door") {
        ctx.save()
        ctx.globalAlpha = 0.6
        Draw.door(ctx, shape, true)
        ctx.restore()
    } else if (shape.type === "dimension") {
        Draw.dimension(ctx, shape)
    }
}

function wallRect(ctx, g, s) {
    polygonPath(ctx, g.corners)
    ctx.fillStyle = s.color || colors.wallFill
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

function lengthLabel(ctx, s) {
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
    const p = Geometry.canvasToScreen({ x: px, y: py })
    // Label text
    const lengthFeet = Math.hypot(s.x2 - s.x1, s.y2 - s.y1)
    const label = Geometry.formatFeetInches(lengthFeet)
    ctx.save()
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.font = "12px sans-serif"
    ctx.fillStyle = "#ffffff"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillText(label, p.x, p.y)
    ctx.restore()
}

function windowRect(ctx, g, s, preview) {
    ctx.save();
    // fill
    polygonPath(ctx, g.corners);
    ctx.fillStyle = preview ?
        "rgba(0,255,136,0.2)" : (s.color || "rgba(174,174,174,0.5)")
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

function door(ctx, door, preview = false) {
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
    ctx.strokeStyle = door.color || "rgba(255,255,255,0.5)";
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

function dimension(ctx, s, barSizePx = 4) {
    // world (feet) → canvas (pixels)
    const x1Feet = s.x1
    const y1Feet = s.y1
    const x2Feet = s.x2
    const y2Feet = s.y2
    const x1 = x1Feet * pixelsPerFoot
    const y1 = y1Feet * pixelsPerFoot
    const x2 = x2Feet * pixelsPerFoot
    const y2 = y2Feet * pixelsPerFoot
    // Vector from start → end
    const dx = x2 - x1;
    const dy = y2 - y1;
    const length = Math.hypot(dx, dy) || 1; // prevent divide-by-zero
    const isVertical = Math.abs(dy) > Math.abs(dx);
    // Main line
    ctx.strokeStyle = s.color || colors.white;
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
    const label = Geometry.formatFeetInches(lengthFeet);
    // Midpoint
    const mx = (x1 + x2) / 2;
    const my = (y1 + y2) / 2;
    // Perpendicular offset for label
    const labelOffsetPx = 14 / zoom;
    const ox = (dy / length) * labelOffsetPx;
    const oy = (-dx / length) * labelOffsetPx;
    // Convert midpoint + offset to screen space
    const p = Geometry.canvasToScreen({ x: mx + ox, y: my + oy });
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
    ctx.fillStyle = s.color || colors.white
    ctx.font = "12px sans-serif"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    // draw at origin
    ctx.fillText(label, 0, 0)
    ctx.restore()
}

function angleVisualizer(ctx, cx, cy, angleRad, zoom) {
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

function makeHorizontal(shape) {
    const x1 = shape.x1;
    const y1 = shape.y1;
    const x2 = shape.x2;
    const y2 = shape.y2;
    const dx = x2 - x1;
    const dy = y2 - y1;
    const r = Math.sqrt(dx * dx + dy * dy);
    // Preserve original horizontal direction
    const dir = Math.sign(dx) || 1; // fallback if dx == 0
    shape.y2 = y1;
    shape.x2 = x1 + dir * r;
    canvas.requestPaint();
}

function makeVertical(shape) {
    const x1 = shape.x1;
    const y1 = shape.y1;
    const x2 = shape.x2;
    const y2 = shape.y2;
    const dx = x2 - x1;
    const dy = y2 - y1;
    const r = Math.sqrt(dx * dx + dy * dy);
    // Preserve original vertical direction
    const dir = Math.sign(dy) || 1; // fallback if dy == 0
    shape.x2 = x1;
    shape.y2 = y1 + dir * r;
    canvas.requestPaint();
}

function moveShape(s, direction, step = 0.25) {
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

function snapValue(v) {
    var snapStepFeet = 1.0;
    return Math.round(v / snapStepFeet) * snapStepFeet
}

// When snapping left or right, only snap x-coordinate 
// of that point to the nearest vertical grid line.
// When snapping up or down, only snap y-coordinate 
// of that point to the nearest horizontal grid line.
function snapShape(s, direction) {
    pushUndoState();
    // Snap
    let target, delta;
    switch (direction) {
        case "left":
            target = snapValue(s.x1);
            if (!s.snap.right) {
                delta = target - s.x1;
                s.x1 += delta;
                s.x2 += delta; // translate whole wall
            } else {
                s.x1 = target; // resize only
            }
            s.snap.left = true;
            break;
        case "right":
            target = snapValue(s.x2);
            if (!s.snap.left) {
                delta = target - s.x2;
                s.x1 += delta;
                s.x2 += delta;
            } else {
                s.x2 = target;
            }
            s.snap.right = true;
            break;
        case "up":
            // pick the point closer to x-axis (smaller y)
            if (s.y1 < s.y2) {
                target = snapValue(s.y1);
                if (!s.snap.bottom) {
                    delta = target - s.y1;
                    s.y1 += delta;
                    s.y2 += delta; // translate whole wall
                } else {
                    s.y1 = target;
                }
                s.snap.top = true;
            } else {
                target = snapValue(s.y2);
                if (!s.snap.bottom) {
                    delta = target - s.y2;
                    s.y1 += delta;
                    s.y2 += delta;
                } else {
                    s.y2 = target;
                }
                s.snap.top = true;
            }
            break;
        case "down":
            // pick the point farther from x-axis (larger y)
            if (s.y1 > s.y2) {
                target = snapValue(s.y1);
                if (!s.snap.top) {
                    delta = target - s.y1;
                    s.y1 += delta;
                    s.y2 += delta;
                } else {
                    s.y1 = target;
                }
                s.snap.bottom = true;
            } else {
                target = snapValue(s.y2);
                if (!s.snap.top) {
                    delta = target - s.y2;
                    s.y1 += delta;
                    s.y2 += delta;
                } else {
                    s.y2 = target;
                }
                s.snap.bottom = true;
            }
            break;
    }
    canvas.requestPaint();
}