#!/usr/bin/env python3
"""Rebuild original VNB vector marks and desktop icons using macOS system tools.

No pip dependency; requires macOS, Swift/Command Line Tools and bundled Noto Sans SC.
SVG text is outlined from the licensed font. Runtime never requires these tools.
"""
import json
from pathlib import Path
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/branding'
INK = '#243b47'
WHITE = '#edf3f1'
ACCENT = '#86bbb9'
# Shared uprights join V, the narrow-waisted N and the two open B counters.
MARK = ('M8 28H20L32 78L44 28H56L38 100H26Z '
        'M50 28H61V100H50Z '
        'M50 28H62L69 56L74 72L85 88V100H73L66 72L61 56L50 42Z '
        'M83 28H97C111 28 119 36 119 47C119 55 115 61 108 64'
        'C117 68 122 74 122 83C122 94 113 100 99 100H83Z '
        'M94 39V58H97C105 58 108 54 108 48C108 42 104 39 97 39Z '
        'M94 70V89H99C107 89 111 86 111 80C111 74 106 70 99 70Z')

SWIFT = r'''
import AppKit
import CoreText
func number(_ value: CGFloat) -> String { String(format: "%.3f", Double(value)) }
let args = CommandLine.arguments
if args[1] == "outline" {
 let data = CGDataProvider(url: URL(fileURLWithPath: args[2]) as CFURL)!
 let graphics = CGFont(data)!
 let baseFont = CTFontCreateWithGraphicsFont(graphics, 64, nil, nil)
 let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: [NSNumber(value: 0x77676874): NSNumber(value: 500)]] as CFDictionary)
 let font = CTFontCreateCopyWithAttributes(baseFont, 64, nil, descriptor)
 let string = NSAttributedString(string: args[3], attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
 let line = CTLineCreateWithAttributedString(string)
 var commands: [String] = []
 for item in CTLineGetGlyphRuns(line) as NSArray {
  let run = item as! CTRun
  let count = CTRunGetGlyphCount(run)
  var glyphs = [CGGlyph](repeating: 0, count: count)
  var points = [CGPoint](repeating: .zero, count: count)
  CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
  CTRunGetPositions(run, CFRange(location: 0, length: 0), &points)
  for i in 0..<count {
   let origin = points[i]
   if let path = CTFontCreatePathForGlyph(font, glyphs[i], nil) {
    path.applyWithBlock { ptr in
     let element = ptr.pointee
     func p(_ i: Int) -> String { number(element.points[i].x + origin.x) + " " + number(76 - element.points[i].y) }
     switch element.type {
     case .moveToPoint: commands.append("M" + p(0))
     case .addLineToPoint: commands.append("L" + p(0))
     case .addQuadCurveToPoint: commands.append("Q" + p(0) + " " + p(1))
     case .addCurveToPoint: commands.append("C" + p(0) + " " + p(1) + " " + p(2))
     case .closeSubpath: commands.append("Z")
     @unknown default: fatalError("Unknown font outline")
     }
    }
   }
  }
 }
 let result: [String: Any] = ["path": commands.joined(separator: " "), "width": CTLineGetTypographicBounds(line, nil, nil, nil)]
 let json = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
 print(String(data: json, encoding: .utf8)!)
} else if args[1] == "raster" {
 guard let image = NSImage(contentsOfFile: args[2]) else { fatalError("Cannot decode SVG") }
 let width = Int(args[4])!, height = Int(args[5])!
 let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
 NSGraphicsContext.saveGraphicsState()
 NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
 NSGraphicsContext.current!.imageInterpolation = .high
 image.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
 NSGraphicsContext.restoreGraphicsState()
 try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[3]))
}
'''


def svg(width, height, content):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" '
            'viewBox="0 0 %s %s">%s</svg>\n' % (width, height, width, height, content))


def mark(color=INK):
    return '<path fill="%s" d="%s"/>' % (color, MARK)


def main():
    OUT.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='vnb-brand-') as temporary:
        temp = Path(temporary)
        helper = temp / 'brand.swift'
        helper.write_text(SWIFT)
        executable = temp / 'brand'
        subprocess.run(['swiftc', '-module-cache-path', str(Path(tempfile.gettempdir()) / 'vnb-brand-module-cache'),
                        str(helper), '-o', str(executable)], check=True)
        def raster(path, destination, width, height=None):
            subprocess.run([str(executable), 'raster', str(path), str(destination),
                            str(width), str(height or width)], check=True)
        font = ROOT / 'assets/fonts/NotoSansSC-Variable.ttf'
        marks = {}
        for locale, title in [('zh', '冯·诺依曼瓶颈'), ('en', 'VON NEUMANN BOTTLENECK')]:
            outline = json.loads(subprocess.check_output([str(executable), 'outline', str(font), title], text=True))
            width = round(outline['width'] + 4)
            body = '<path fill="%s" d="%s"/>' % (INK, outline['path'])
            (OUT / ('logo-' + locale + '.svg')).write_text(svg(width, 96, body))
            (OUT / ('logo-' + locale + '-light.svg')).write_text(svg(width, 96, body.replace(INK, WHITE)))
            # The full lockup is a shareable, self-contained vector; configured
            # wordmarks omit the symbol so runtime can lay out both appropriately.
            lockup = ('<g transform="translate(0,-16)">' + mark() + '</g>'
                      '<g transform="translate(144,0)">' + body + '</g>')
            (OUT / ('full-logo-' + locale + '.svg')).write_text(svg(width + 148, 96, lockup))
            marks[locale] = (width, body)
        (OUT / 'symbol.svg').write_text(svg(128, 128, mark()))
        (OUT / 'symbol-light.svg').write_text(svg(128, 128, mark(WHITE)))
        (OUT / 'symbol-black.svg').write_text(svg(128, 128, mark('#000000')))
        (OUT / 'symbol-white.svg').write_text(svg(128, 128, mark('#ffffff')))
        icon = '<rect x="4" y="4" width="120" height="120" rx="26" fill="%s"/>' % INK
        icon += '<g transform="translate(6.4,6.4) scale(.9)">' + mark(WHITE) + '</g>'
        # Quiet accent on the N waist, visible at useful sizes but nonessential.
        icon += '<path fill="%s" d="M59 57L62 65L67 72L64 64Z"/>' % ACCENT
        (OUT / 'game-icon.svg').write_text(svg(128, 128, icon))
        sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024]
        pngs = {}
        for size in sizes:
            target = temp / ('icon-%s.png' % size)
            raster(OUT / 'game-icon.svg', target, size)
            pngs[size] = target.read_bytes()
        ico_sizes = [16, 24, 32, 48, 64, 128, 256]
        header = struct.pack('<HHH', 0, 1, len(ico_sizes))
        offset = 6 + 16 * len(ico_sizes)
        entries = b''
        for size in ico_sizes:
            data = pngs[size]
            entries += struct.pack('<BBBBHHII', size % 256, size % 256, 0, 0, 1, 32, len(data), offset)
            offset += len(data)
        (OUT / 'game-icon.ico').write_bytes(header + entries + b''.join(pngs[x] for x in ico_sizes))
        icns = b''
        for tag, size in [('icp4', 16), ('icp5', 32), ('icp6', 64), ('ic07', 128), ('ic08', 256), ('ic09', 512), ('ic10', 1024)]:
            data = pngs[size]
            icns += tag.encode() + struct.pack('>I', len(data) + 8) + data
        (OUT / 'game-icon.icns').write_bytes(b'icns' + struct.pack('>I', len(icns) + 8) + icns)
        # Self-contained review sheet; labels use outlines too (no font dependency).
        sheet = '<rect width="1000" height="650" fill="#f3f3ed"/>'
        sheet += '<rect x="500" width="500" height="650" fill="%s"/>' % INK
        for x, color in [(64, INK), (564, WHITE)]:
            sheet += '<g transform="translate(%s,26) scale(1.7)">%s</g>' % (x, mark(color))
            for y, locale in [(250, 'zh'), (330, 'en')]:
                width, body = marks[locale]
                scale = min(400 / width, .72)
                sheet += '<g transform="translate(%s,%s) scale(%s)">%s</g>' % (x, y, scale, body.replace(INK, color))
            cursor = x
            for size in [16, 24, 32, 48, 64, 128]:
                sheet += '<g transform="translate(%s,440) scale(%s)">%s</g>' % (cursor, size / 128, icon)
                cursor += size + 12
            sheet += '<g transform="translate(%s,540) scale(.65)">%s</g>' % (x, mark('#000000' if x == 64 else '#ffffff'))
        (OUT / 'brand-review.svg').write_text(svg(1000, 650, sheet))
        raster(OUT / 'brand-review.svg', OUT / 'brand-review.png', 1000, 650)
        (OUT / 'game-icon-128.png').write_bytes(pngs[128])
    print('PASS: generated outlined bilingual brand, 16–1024 px native icons and review sheet')


if __name__ == '__main__':
    main()
