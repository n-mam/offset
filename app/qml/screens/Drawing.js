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
        Draw.window(ctx, g, shape, true)
        ctx.restore()
    } else if (shape.type === "door") {
        ctx.save()
        ctx.globalAlpha = 0.6
        Draw.door(ctx, shape, true)
        ctx.restore()
    } else if (shape.type === "dimension") {
        Draw.dimension(ctx, shape)
    } else if(shape.type === "stair") {
        Draw.stair(ctx, shape)
    }
}

function stair(ctx, s) {
    const sg = Shape.stairGeometry(s, pixelsPerFoot);
    if (!sg) return;
    // Draw outer stair body
    wallRect(ctx, sg.base, s);
    // Draw treads
    ctx.strokeStyle = "#555";
    ctx.lineWidth = 1 / zoom;
    sg.steps.forEach(step => {
        ctx.beginPath();
        ctx.moveTo(step.x1, step.y1);
        ctx.lineTo(step.x2, step.y2);
        ctx.stroke();
    });
    // Draw landing
    if (sg.landing && sg.landing.length) {
        wallRect(ctx, { corners: sg.landing }, s);
    }
}

function wallRect(ctx, g, s) {
    // Fill wall
    polygonPath(ctx, g.corners);
    ctx.fillStyle = s.color || colors.wallFill;
    ctx.fill();
    // Outline wall
    polygonPath(ctx, g.corners);
    ctx.strokeStyle = colors.wallOutline;
    ctx.lineWidth = 1 / zoom;
    ctx.stroke();
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

function window(ctx, g, s, preview) {
    ctx.save();
    polygonPath(ctx, g.corners);
    ctx.fillStyle = preview ? "rgba(0,255,136,0.2)" : 
        (s.color || "rgba(174,174,174,0.5)")
    ctx.fill();
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

function door(ctx, s, preview) {
    // start and end points
    const sx = (s.swing ? s.x1 : s.x2) * pixelsPerFoot; // hinge
    const sy = (s.swing ? s.y1 : s.y2) * pixelsPerFoot;
    const ex = (s.swing ? s.x2 : s.x1) * pixelsPerFoot; // base end
    const ey = (s.swing ? s.y2 : s.y1) * pixelsPerFoot;
    const r = Math.hypot(ex - sx, ey - sy);
    // base angle
    const a = Math.atan2(ey - sy, ex - sx);
    let startAngle, endAngle;
    if (s.swing) {
      startAngle = a - Math.PI / 2;
      endAngle = a;
    } else {
      startAngle = a;
      endAngle = a + Math.PI / 2;
    }
    // arc end point (top-left edge)
    const ax = sx + Math.cos(s.swing ? startAngle : endAngle) * r;
    const ay = sy + Math.sin(s.swing ? startAngle : endAngle) * r;
    ctx.save();
    // fill the door swing area with corrected path order
    ctx.fillStyle = preview ? "rgba(0,255,136,0.2)" :
        "rgba(255,255,255,0.15)";
    ctx.beginPath();
    ctx.moveTo(sx, sy);                          // hinge
    ctx.arc(sx, sy, r, startAngle, endAngle);    // arc
    ctx.lineTo(sx, sy);                          // base end
    ctx.closePath();
    ctx.fill();
    // stroke line from arc end back to hinge in white
    ctx.beginPath();
    ctx.moveTo(ax, ay);
    ctx.lineTo(sx, sy);
    ctx.strokeStyle = "white";
    ctx.lineWidth = 1 / zoom;
    ctx.stroke();
    // base (filled thick line)
    const halfThickness = (s.thickness * pixelsPerFoot) / 2;
    const dx = (ey - sy) / r * halfThickness; // perpendicular offset x
    const dy = (ex - sx) / r * halfThickness; // perpendicular offset y
    ctx.fillStyle = s.color || "rgba(152, 132, 132, 0.26)";
    ctx.strokeStyle = "black";
    ctx.lineWidth = 1 / zoom;
    ctx.beginPath();
    ctx.moveTo(sx - dx, sy + dy);
    ctx.lineTo(ex - dx, ey + dy);
    ctx.lineTo(ex + dx, ey - dy);
    ctx.lineTo(sx + dx, sy - dy);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    // dashed arc line
    ctx.strokeStyle = "white";
    ctx.lineWidth = 2 / zoom;
    ctx.setLineDash([1.5 / zoom, 1.5 / zoom]);
    ctx.beginPath();
    ctx.arc(sx, sy, r, startAngle, endAngle);
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