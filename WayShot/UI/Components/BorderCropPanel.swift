import SwiftUI

public struct BorderCropPanel: View {
    @Binding public var crop: CropTransform
    @Binding public var border: Border

    public init(crop: Binding<CropTransform>, border: Binding<Border>) {
        self._crop = crop
        self._border = border
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Aspect Ratio Section
            Text("ASPECT RATIO")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(1)
                .foregroundColor(ColorTokens.textMuted)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AspectRatio.allCases) { ratio in
                        let isSelected = crop.aspectRatio == ratio

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                crop.aspectRatio = ratio
                            }
                        }) {
                            HStack(spacing: 6) {
                                // Miniature ratio box
                                miniRatioBox(ratio: ratio, isSelected: isSelected)

                                Text(ratio.label)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : ColorTokens.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? ColorTokens.cherryPrimary : ColorTokens.bgSurfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }

            // Vintage Frames Section
            Text("VINTAGE FRAMES")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(1)
                .foregroundColor(ColorTokens.textMuted)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BorderType.allCases) { bType in
                        let isSelected = border.type == bType

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                border.type = bType
                            }
                        }) {
                            Text(bType.label)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : ColorTokens.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? ColorTokens.cherryPrimary : ColorTokens.bgSurfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }

            if border.type != .none {
                AestheticSlider(
                    label: "Frame Thickness",
                    value: $border.widthPercent,
                    range: 0.02...0.15,
                    defaultValue: 0.05,
                    isPercentage: true
                )
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private func miniRatioBox(ratio: AspectRatio, isSelected: Bool) -> some View {
        let borderColor = isSelected ? Color.white : ColorTokens.textMuted
        switch ratio {
        case .original, .ratio1_1:
            RoundedRectangle(cornerRadius: 2)
                .stroke(borderColor, lineWidth: 1)
                .frame(width: 13, height: 13)
        case .ratio4_5, .ratio3_4:
            RoundedRectangle(cornerRadius: 2)
                .stroke(borderColor, lineWidth: 1)
                .frame(width: 10, height: 13)
        case .ratio9_16:
            RoundedRectangle(cornerRadius: 2)
                .stroke(borderColor, lineWidth: 1)
                .frame(width: 8, height: 14)
        case .ratio16_9:
            RoundedRectangle(cornerRadius: 2)
                .stroke(borderColor, lineWidth: 1)
                .frame(width: 14, height: 8)
        case .ratioFacebook:
            RoundedRectangle(cornerRadius: 2)
                .stroke(borderColor, lineWidth: 1)
                .frame(width: 15, height: 8)
        }
    }
}
