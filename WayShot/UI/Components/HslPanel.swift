import SwiftUI

public struct HslPanel: View {
    @Binding public var hsl: HslAdjustment
    @State private var selectedBand: HslBand = .red
    public let onRequirePro: () -> Void

    public init(hsl: Binding<HslAdjustment>, onRequirePro: @escaping () -> Void = {}) {
        self._hsl = hsl
        self.onRequirePro = onRequirePro
    }

    private func colorForBand(_ band: HslBand) -> Color {
        switch band {
        case .red: return Color(hex: "#EF4444")
        case .orange: return Color(hex: "#F97316")
        case .yellow: return Color(hex: "#EAB308")
        case .green: return Color(hex: "#22C55E")
        case .aqua: return Color(hex: "#06B6D4")
        case .blue: return Color(hex: "#3B82F6")
        case .purple: return Color(hex: "#A855F7")
        case .magenta: return Color(hex: "#EC4899")
        }
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Band Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HslBand.allCases) { band in
                        let isSelected = band == selectedBand
                        let channel = hsl.bands[band] ?? HslChannel()
                        let isModified = channel.hue != 0 || channel.saturation != 0 || channel.luminance != 0

                        Button(action: {
                            if !ProSubscriptionManager.shared.isPro {
                                onRequirePro()
                            } else {
                                selectedBand = band
                            }
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(colorForBand(band))
                                        .frame(width: 26, height: 26)

                                    if isSelected {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 32, height: 32)
                                    }
                                }

                                Text(band.rawValue.prefix(3))
                                    .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : ColorTokens.textMuted)

                                if isModified {
                                    Circle()
                                        .fill(ColorTokens.cherryPrimary)
                                        .frame(width: 4, height: 4)
                                } else {
                                    Spacer().frame(height: 4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // Sliders for the active band
            let activeChannel = hsl.bands[selectedBand] ?? HslChannel()

            VStack(spacing: 4) {
                AestheticSlider(
                    label: "\(selectedBand.rawValue) Hue",
                    value: Binding(
                        get: { activeChannel.hue },
                        set: { updateBand(hue: $0, sat: activeChannel.saturation, lum: activeChannel.luminance) }
                    ),
                    range: -180...180
                )

                AestheticSlider(
                    label: "\(selectedBand.rawValue) Saturation",
                    value: Binding(
                        get: { activeChannel.saturation },
                        set: { updateBand(hue: activeChannel.hue, sat: $0, lum: activeChannel.luminance) }
                    ),
                    range: -100...100
                )

                AestheticSlider(
                    label: "\(selectedBand.rawValue) Luminance",
                    value: Binding(
                        get: { activeChannel.luminance },
                        set: { updateBand(hue: activeChannel.hue, sat: activeChannel.saturation, lum: $0) }
                    ),
                    range: -100...100
                )
            }
        }
    }

    private func updateBand(hue: Float, sat: Float, lum: Float) {
        if !ProSubscriptionManager.shared.isPro {
            onRequirePro()
            return
        }
        var newBands = hsl.bands
        newBands[selectedBand] = HslChannel(hue: hue, saturation: sat, luminance: lum)
        hsl.bands = newBands
    }
}
