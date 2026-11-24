import AppKit
import UniformTypeIdentifiers

func drawCleanDiskVector(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let inset = size * 0.06
    let squircleRect = rect.insetBy(dx: inset, dy: inset)

    // Clip to Squircle
    let clipPath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.saveGState()
    ctx.addPath(clipPath)
    ctx.clip()

    // Background Gradient: Deep Slate to Cobalt & Cyan
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1.0).cgColor,
        NSColor(red: 0.12, green: 0.23, blue: 0.54, alpha: 1.0).cgColor,
        NSColor(red: 0.01, green: 0.52, blue: 0.78, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
    if let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size, y: size), options: [])
    }

    // Inner rim stroke
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.15).cgColor)
    ctx.setLineWidth(size * 0.012)
    ctx.addPath(clipPath)
    ctx.strokePath()

    // External Disk Body
    let driveRect = CGRect(x: size * 0.26, y: size * 0.22, width: size * 0.48, height: size * 0.30)
    let drivePath = CGPath(roundedRect: driveRect, cornerWidth: size * 0.045, cornerHeight: size * 0.045, transform: nil)

    // Shadow under drive
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.04, color: NSColor.black.withAlphaComponent(0.4).cgColor)

    let driveColors = [
        NSColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor,
        NSColor(red: 0.80, green: 0.84, blue: 0.90, alpha: 1.0).cgColor
    ] as CFArray
    if let driveGrad = CGGradient(colorsSpace: colorSpace, colors: driveColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.addPath(drivePath)
        ctx.clip()
        ctx.drawLinearGradient(driveGrad, start: CGPoint(x: 0, y: size * 0.52), end: CGPoint(x: 0, y: size * 0.22), options: [])
        ctx.restoreGState()
    }

    // Reset shadow
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Drive line groove
    ctx.setFillColor(NSColor(red: 0.58, green: 0.64, blue: 0.72, alpha: 1.0).cgColor)
    ctx.fill(CGRect(x: size * 0.30, y: size * 0.46, width: size * 0.40, height: size * 0.015))

    // LED Indicator (Emerald Green)
    ctx.setFillColor(NSColor(red: 0.06, green: 0.75, blue: 0.45, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: CGRect(x: size * 0.32, y: size * 0.29, width: size * 0.05, height: size * 0.05))

    // Drive Slot
    ctx.setFillColor(NSColor(red: 0.28, green: 0.33, blue: 0.42, alpha: 1.0).cgColor)
    let slotPath = CGPath(roundedRect: CGRect(x: size * 0.42, y: size * 0.29, width: size * 0.26, height: size * 0.035), cornerWidth: size * 0.015, cornerHeight: size * 0.015, transform: nil)
    ctx.addPath(slotPath)
    ctx.fillPath()

    // Vector Sparkle drawing function
    func drawSparkle(center: CGPoint, radius: CGFloat, color: NSColor) {
        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.setShadow(offset: .zero, blur: radius * 0.4, color: color.withAlphaComponent(0.6).cgColor)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x, y: center.y + radius))
        path.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: center)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // Sparkles
    let gold = NSColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 1.0)
    drawSparkle(center: CGPoint(x: size * 0.68, y: size * 0.68), radius: size * 0.17, color: gold)
    drawSparkle(center: CGPoint(x: size * 0.36, y: size * 0.65), radius: size * 0.10, color: .white)
    drawSparkle(center: CGPoint(x: size * 0.72, y: size * 0.38), radius: size * 0.065, color: .white)

    ctx.restoreGState()
    image.unlockFocus()
    return image
}

let outURL: URL
if CommandLine.arguments.count > 1 {
    outURL = URL(fileURLWithPath: CommandLine.arguments[1])
} else {
    outURL = URL(fileURLWithPath: "AppIcon.icns")
}

guard let destination = CGImageDestinationCreateWithURL(
    outURL as CFURL,
    UTType.icns.identifier as CFString,
    7,
    nil
) else {
    print("❌ Failed to create ICNS destination")
    exit(1)
}

let resolutions: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
for s in resolutions {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(s),
        pixelsHigh: Int(s),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let img = drawCleanDiskVector(size: s)
    img.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
    NSGraphicsContext.restoreGraphicsState()

    if let cgImage = rep.cgImage {
        CGImageDestinationAddImage(destination, cgImage, nil)
    }
}

if CGImageDestinationFinalize(destination) {
    print("✅ Successfully generated vector icon: \(outURL.path)")
} else {
    print("❌ Failed to finalize ICNS")
    exit(1)
}
