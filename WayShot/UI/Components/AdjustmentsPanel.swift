import SwiftUI

public enum AdjustmentItem: String, CaseIterable, Identifiable {
    case brightness = "Brightness"
    case contrast = "Contrast"
    case saturation = "Saturation"
    case warmth = "Warmth"
    case sharpen = "Sharpen"
    case highlights = "Highlights"
    case shadows = "Shadows"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .brightness: return "sun.max.fill"
        case .contrast: return "circle.righthalf.filled"
        case .saturation: return "drop.fill"
        case .warmth: return "flame.fill"
        case .sharpen: return "triangle.fill"
        case .highlights: return "sun.haze.fill"
        case .shadows: return "moon.fill"
        }
    }
}

public struct AdjustmentsPanel: View {
    @Binding public var adjustments: Adjustments
    @State private var selectedItem: AdjustmentItem = .brightness

    public init(adjustments: Binding<Adjustments>) {
        self._adjustments = adjustments
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Active slider based on selected adjustment
            switch selectedItem {
            case .brightness:
                AestheticSlider(
                    label: "Brightness",
                    value: $adjustments.brightness,
                    range: -100...100
                )
            case .contrast:
                AestheticSlider(
                    label: "Contrast",
                    value: $adjustments.contrast,
                    range: -100...100
                )
            case .saturation:
                AestheticSlider(
                    label: "Saturation",
                    value: $adjustments.saturation,
                    range: -100...100
                )
            case .warmth:
                AestheticSlider(
                    label: "Warmth",
                    value: $adjustments.warmth,
                    range: -100...100
                )
            case .sharpen:
                AestheticSlider(
                    label: "Sharpen",
                    value: $adjustments.sharpen,
                    range: 0...100
                )
            case .highlights:
                AestheticSlider(
                    label: "Highlights",
                    value: $adjustments.highlights,
                    range: -100...100
                )
            case .shadows:
                AestheticSlider(
                    label: "Shadows",
                    value: $adjustments.shadows,
                    range: -100...100
                )
            }

            // Horizontal items selector with icons & active dot indicators
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AdjustmentItem.allCases) { item in
                        let isSelected = item == selectedItem
                        let itemValue: Float = {
                            switch item {
                            case .brightness: return adjustments.brightness
                            case .contrast: return adjustments.contrast
                            case .saturation: return adjustments.saturation
                            case .warmth: return adjustments.warmth
                            case .sharpen: return adjustments.sharpen
                            case .highlights: return adjustments.highlights
                            case .shadows: return adjustments.shadows
                            }
                        }()
                        let isModified = Int(round(itemValue)) != 0

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
