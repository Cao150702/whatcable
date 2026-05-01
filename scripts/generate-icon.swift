#!/usr/bin/env swift
// Renders the cable.connector SF Symbol onto a rounded-rect background
// and emits a PNG. Used by build-app.sh to produce AppIcon.icns.

import Cocoa

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: generate-icon.swift <size> <output.png>\n".utf8))
    exit(1)
}

let size = CGFloat(Int(CommandLine.arguments[1]) ?? 1024)
let outPath = CommandLine.arguments[2]

let canvas = NSRect(x: 0, y: 0, width: size, height: size)

let image = NSImage(size: canvas.size, flipped: false) { rect in
    // Squircle background with macOS Big Sur-style corner radius
    let radius = size * 0.2237
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(
        starting: NSColor(srgbRed: 0.10, green: 0.42, blue: 0.95, alpha: 1.0),
        ending:   NSColor(srgbRed: 0.04, green: 0.18, blue: 0.55, alpha: 1.0)
    )!
    gradient.draw(in: path, angle: -90)

    // Subtle inner highlight at the top to match Apple's app icon look
    NSGraphicsContext.current?.saveGraphicsState()
    path.addClip()
    let highlight = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.18),
        NSColor.white.withAlphaComponent(0.0)
    ])!
    highlight.draw(in: NSRect(x: 0, y: size * 0.55, width: size, height: size * 0.45), angle: -90)
    NSGraphicsContext.current?.restoreGraphicsState()

    // SF Symbol foreground, white
    let pointSize = size * 0.58
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))

    if let symbol = NSImage(systemSymbolName: "cable.connector", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symSize = symbol.size
        let dest = NSRect(
            x: (size - symSize.width) / 2,
            y: (size - symSize.height) / 2,
            width: symSize.width,
            height: symSize.height
        )
        symbol.draw(in: dest)
    } else {
        FileHandle.standardError.write(Data("symbol not found\n".utf8))
    }
    return true
}

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("encode failed\n".utf8))
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outPath))
