import SwiftUI

public struct AestheticSlider: View {
    public let label: String
    @Binding public var value: Float
    public let range: ClosedRange<Float>
    public let defaultValue: Float
    public let isPercentage: Bool

    public init(
        label: String,
        value: Binding<Float>,
        range: ClosedRange<Float> = -100...100,
        defaultValue: Float? = nil,
        isPercentage: Bool = false
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.defaultValue = defaultValue ?? (range.lowerBound < 0 ? 0 : range.lowerBound)
        self.isPercentage = isPercentage
    }

    private var isModified: Bool {
        if isPercentage {
            return abs(value - defaultValue) > 0.01
        } else {
            return Int(round(value)) != Int(round(defaultValue))
        }
    }

    private var displayValue: String {
        if isPercentage {
            return "\(Int(round(value * 100)))%"
        } else {
            let intVal = Int(round(value))
            return intVal > 0 ? "+\(intVal)" : "\(intVal)"
        }
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(TypographyTokens.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTokens.textSecondary)

                Spacer()

                // Reset badge on tap
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        value = defaultValue
                    }
                }) {
                    Text(displayValue)
                        .font(TypographyTokens.monospacedBadge)
                        .foregroundColor(isModified ? ColorTokens.cherryPrimary : ColorTokens.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            isModified
                            ? ColorTokens.cherryPrimary.opacity(0.18)
                            : ColorTokens.bgSurfaceElevated
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!isModified)
            }

            // Custom styled slider
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound)
            )
            .tint(ColorTokens.cherryPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
