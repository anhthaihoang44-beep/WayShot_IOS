import SwiftUI

public enum EffectItem: String, CaseIterable, Identifiable {
    case grain = "Film Grain"
    case dust = "Dust & Scratches"
    case leaks = "Light Leaks"
    case glow = "Soft Glow"
    case chroma = "Chroma Prism"
    case vhs = "VHS Scanlines"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .grain: return "circle.dotted"
        case .dust: return "smoke.fill"
        case .leaks: return "sun.dust.fill"
        case .glow: return "sparkles"
        case .chroma: return "camera.aperture"
        case .vhs: return "video.fill"
        }
    }
}

public struct EffectsPanel: View {
    @Binding public var effects: Effects
    @State private var selectedItem: EffectItem = .grain

    public init(effects: Binding<Effects>) {
        self._effects = effects
    }

    public var body: some View {
        VStack(spacing: 8) {
            switch selectedItem {
            case .grain:
                AestheticSlider(
                    label: "Film Grain Intensity",
                    value: $effects.grain,
                    range: 0...100
                )
            case .dust:
                AestheticSlider(
                    label: "Dust & Scratches",
                    value: $effects.dust,
                    range: 0...100
                )
            case .leaks:
                AestheticSlider(
                    label: "Light Leaks",
                    value: $effects.leaks,
                    range: 0...100
                )
            case .glow:
                AestheticSlider(
                    label: "Soft Glow Diffusion",
                    value: $effects.glow,
                    range: 0...100
                )
            case .chroma:
                AestheticSlider(
                    label: "Chroma Prism Separation",
                    value: $effects.chroma,
                    range: 0...100
                )
            case .vhs:
                AestheticSlider(
                    label: "VHS Scanline Distortion",
                    value: $effects.vhs,
                    range: 0...100
                )
            }

            // Horizontal selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EffectItem.allCases) { item in
                        let isSelected = item == selectedItem
                        let itemValue: Float = {
                            switch item {
                            case .grain: return effects.grain
                            case .dust: return effects.dust
                            case .leaks: return effects.leaks
                            case .glow: return effects.glow
                            case .chroma: return effects.chroma
                            case .vhs: return effects.vhs
                            }
                        }()
                        let isModified = Int(round(itemValue)) > 0

                        Button(action: { selectedItem = item }) {
                            HStack(spacing: 6) {
                                Image(systemName: item.systemIcon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(
                                        isSelected ? .white : (isModified ? ColorTokens.cherryPrimary : ColorTokens.textSecondary)
                                    )

                                Text(item.rawValue)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : ColorTokens.textSecondary)

                                if isModified && !isSelected {
                                    Circle()
                                        .fill(ColorTokens.cherryPrimary)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? ColorTokens.cherryPrimary : ColorTokens.bgSurfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }
}
