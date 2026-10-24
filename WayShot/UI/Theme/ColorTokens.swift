import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

public enum ColorTokens {
    // Backgrounds
    public static let bgDark = Color(hex: 0x0C0D12)
    public static let bgCanvas = Color(hex: 0x000000)
    public static let bgSurface = Color(hex: 0x141620)
    public static let bgSurfaceElevated = Color(hex: 0x1C1E2B)
    public static let bgSurfaceHover = Color(hex: 0x26293A)
    public static let bgGlass = Color(hex: 0x141620, alpha: 0.8)

    // Borders
    public static let borderSubtle = Color.white.opacity(0.12)
    public static let borderMedium = Color.white.opacity(0.20)
    public static let borderAccent = Color(hex: 0xFF2D55, alpha: 0.40)

    // Cherry Red / Hot Pink Palette inspired by DigiCam / Aesthetic apps
    public static let cherryPrimary = Color(hex: 0xFFFF2D55)
    public static let cherryCrimson = Color(hex: 0xE11D48)
    public static let cherryCoral = Color(hex: 0xFFFF6B81)
    public static let cherryPeach = Color(hex: 0xFFA07A)
    public static let retroOrange = Color(hex: 0xFFFF7A00)
    public static let flashGlow = Color(hex: 0xFFFFE66D)

    // Brand Gradients
    public static let brandGradient = LinearGradient(
        colors: [Color(hex: 0xFFFF2D55), Color(hex: 0xE11D48)],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let brandGradientVertical = LinearGradient(
        colors: [Color(hex: 0xFFFF6B81), Color(hex: 0xE11D48)],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let proBadgeGradient = LinearGradient(
        colors: [Color(hex: 0xFFFFDF00), Color(hex: 0xF59E0B)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Text tokens
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0xA1A1AA)
    public static let textMuted = Color(hex: 0x71717A)
}
