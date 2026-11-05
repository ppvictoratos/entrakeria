import MapKit
import SwiftUI
import UIKit

/// Real terrain, drawn as contour lines in the app's colors.
struct TopoMapView: View {
    let place: String
    let latitude: Double
    let longitude: Double

    @State private var map: TopoMap?
    @State private var failed = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let map {
                Canvas { ctx, size in
                    // The tile fills the width; slide it so the marker stays in view.
                    let scale = size.width
                    let top = min(max(map.marker.y * scale - size.height / 2, 0), scale - size.height)
                    func point(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * scale, y: p.y * scale - top) }
                    func stroke(_ lines: [TopoMap.Segment], _ color: Color, _ width: CGFloat) {
                        var path = Path()
                        for line in lines {
                            path.move(to: point(line.a))
                            path.addLine(to: point(line.b))
                        }
                        ctx.stroke(path, with: .color(color), lineWidth: width)
                    }
                    stroke(map.minor, EnkrateiaPalette.line, 0.75)
                    stroke(map.major, EnkrateiaPalette.bronze, 1)

                    let m = point(map.marker), r: CGFloat = 7
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: m.x, y: m.y - r))
                    diamond.addLine(to: CGPoint(x: m.x + r, y: m.y))
                    diamond.addLine(to: CGPoint(x: m.x, y: m.y + r))
                    diamond.addLine(to: CGPoint(x: m.x - r, y: m.y))
                    diamond.closeSubpath()
                    ctx.fill(diamond, with: .color(EnkrateiaPalette.gold))
                }
            } else {
                Text(failed ? "Map needs a connection." : "Drawing the terrain…")
                    .font(.system(size: 12).italic())
                    .foregroundStyle(EnkrateiaPalette.bronze)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(place.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .kerning(2)
                    .foregroundStyle(EnkrateiaPalette.gold)
                Text(coordinates)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(EnkrateiaPalette.bronze)
            }
            .padding(8)
            .background(EnkrateiaPalette.bg.opacity(0.85))
            .padding(8)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.line, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Topographic map of \(place)")
        .task(id: "\(latitude),\(longitude)") {
            map = nil
            failed = false
            do {
                map = try await TopoMap.load(latitude: latitude, longitude: longitude)
            } catch {
                failed = !Task.isCancelled
            }
        }
    }

    private var coordinates: String {
        String(format: "%.3f° %@  %.3f° %@", abs(latitude), latitude >= 0 ? "N" : "S",
               abs(longitude), longitude >= 0 ? "E" : "W")
    }
}

/// Contours for the map tile around a point, in 0...1 tile coordinates.
struct TopoMap {
    struct Segment { let a, b: CGPoint }

    let minor: [Segment]
    let major: [Segment]
    let marker: CGPoint

    private static let zoom = 13.0
    private static let side = 256

    static func load(latitude: Double, longitude: Double) async throws -> TopoMap {
        let n = pow(2, zoom)
        let x = (longitude + 180) / 360 * n
        let rad = latitude * .pi / 180
        let y = (1 - log(tan(rad) + 1 / cos(rad)) / .pi) / 2 * n

        // AWS Open Data terrain tiles: elevation in meters, encoded in the pixel colors.
        let url = URL(string: "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/\(Int(zoom))/\(Int(x))/\(Int(y)).png")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        let marker = CGPoint(x: x - floor(x), y: y - floor(y))
        return try await Task.detached(priority: .userInitiated) {
            try contours(from: data, marker: marker)
        }.value
    }

    private static func contours(from data: Data, marker: CGPoint) throws -> TopoMap {
        guard let image = UIImage(data: data)?.cgImage, image.width == side, image.height == side else {
            throw URLError(.cannotDecodeContentData)
        }
        // Drawing in the image's own color space leaves the encoded values untouched.
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let space = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &pixels, width: side, height: side, bitsPerComponent: 8,
                                  bytesPerRow: side * 4, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw URLError(.cannotDecodeContentData)
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))

        let raw = (0..<side * side).map { i -> Double in
            let p = i * 4
            return Double(pixels[p]) * 256 + Double(pixels[p + 1]) + Double(pixels[p + 2]) / 256 - 32768
        }

        // Average down to a coarser grid so the lines read as terrain, not noise.
        let block = 3, cells = side / block
        var grid = [Double](repeating: 0, count: cells * cells)
        for row in 0..<cells {
            for col in 0..<cells {
                var sum = 0.0
                for dy in 0..<block { for dx in 0..<block { sum += raw[(row * block + dy) * side + col * block + dx] } }
                grid[row * cells + col] = sum / Double(block * block)
            }
        }

        let low = grid.min() ?? 0, high = grid.max() ?? 0
        let interval = [1.0, 2, 5, 10, 20, 50, 100, 200].first { (high - low) / $0 <= 16 } ?? 500

        var minor: [Segment] = [], major: [Segment] = []
        var level = (low / interval).rounded(.up) * interval
        while level <= high {
            let lines = march(grid, cells: cells, level: level)
            if Int((level / interval).rounded()) % 5 == 0 { major += lines } else { minor += lines }
            level += interval
        }
        return TopoMap(minor: minor, major: major, marker: marker)
    }

    /// Marching squares: where the level crosses each grid cell, draw a line through it.
    private static func march(_ grid: [Double], cells: Int, level: Double) -> [Segment] {
        var out: [Segment] = []
        let unit = 1 / Double(cells - 1)
        for row in 0..<(cells - 1) {
            for col in 0..<(cells - 1) {
                let tl = grid[row * cells + col], tr = grid[row * cells + col + 1]
                let br = grid[(row + 1) * cells + col + 1], bl = grid[(row + 1) * cells + col]
                func cross(_ a: Double, _ b: Double) -> Double? {
                    (a < level) != (b < level) ? (level - a) / (b - a) : nil
                }
                var hits: [CGPoint] = []
                if let t = cross(tl, tr) { hits.append(CGPoint(x: (Double(col) + t) * unit, y: Double(row) * unit)) }
                if let t = cross(tr, br) { hits.append(CGPoint(x: Double(col + 1) * unit, y: (Double(row) + t) * unit)) }
                if let t = cross(bl, br) { hits.append(CGPoint(x: (Double(col) + t) * unit, y: Double(row + 1) * unit)) }
                if let t = cross(tl, bl) { hits.append(CGPoint(x: Double(col) * unit, y: (Double(row) + t) * unit)) }
                if hits.count >= 2 { out.append(Segment(a: hits[0], b: hits[1])) }
                if hits.count == 4 { out.append(Segment(a: hits[2], b: hits[3])) }
            }
        }
        return out
    }

    /// Finds the coordinates for a place name with Apple's search.
    static func coordinate(for place: String) async throws -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = place
        return try await MKLocalSearch(request: request).start().mapItems.first?.placemark.coordinate
    }
}
