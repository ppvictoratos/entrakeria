import SwiftUI

enum EnkrateiaPalette {
    static let bg = Color(hex: "1C1410")        // near-black espresso
    static let clay = Color(hex: "B5651D")      // terracotta orange
    static let bronze = Color(hex: "8B5A2B")    // aged bronze brown
    static let gold = Color(hex: "D4A24C")      // highlight/active
    static let line = Color(hex: "4A3220")      // dim line art
    static let parchment = Color(hex: "E8D9C4") // readable body text
}

extension Color {
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(.sRGB, red: Double((v >> 16) & 0xFF)/255,
                   green: Double((v >> 8) & 0xFF)/255,
                   blue: Double(v & 0xFF)/255, opacity: 1)
    }
}
