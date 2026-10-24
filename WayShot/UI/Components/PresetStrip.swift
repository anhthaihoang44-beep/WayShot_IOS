import SwiftUI

public struct PresetStrip: View {
    public let presets: [Preset]
    public let selectedPresetId: String?
    public let presetIntensity: Float
    public let onSelectPreset: (Preset?) -> Void
    public let onIntensityChange: (Float) -> Void
    public let onRequirePro: () -> Void

    @State private var selectedCategory: String = "All"

    public init(
        presets: [Preset],
        selectedPresetId: String?,
        presetIntensity: Float,
        onSelectPreset: @escaping (Preset?) -> Void,
        onIntensityChange: @escaping (Float) -> Void,
        onRequirePro: @escaping () -> Void = {}
    ) {
        self.presets = presets
        self.selectedPresetId = selectedPresetId
        self.presetIntensity = presetIntensity
        self.onSelectPreset = onSelectPreset
        self.onIntensityChange = onIntensityChange
        self.onRequirePro = onRequirePro
    }

    private var categories: [String] {
        var cats = ["All"]
        let distinct = Array(Set(presets.map { $0.category })).sorted()
        cats.append(contentsOf: distinct)
        return cats
    }

    private var filteredPresets: [Preset] {
        if selectedCategory == "All" {
            return presets
        } else {
            return presets.filter { $0.category == selectedCategory }
        }
    }

    public var body: some View {
        VStack(spacing: 6) {
            // Intensity slider when preset is selected
            if selectedPresetId != nil {
                AestheticSlider(
                    label: "Filter Intensity",
                    value: Binding(
                        get: { presetIntensity },
                        set: { onIntensityChange($0) }
                    ),
                    range: 0.0...1.0,
                    defaultValue: 1.0,
                    isPercentage: true
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        let isSelected = cat == selectedCategory
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCategory = cat
                            }
                        }) {
                            Text(cat)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : ColorTokens.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(isSelected ? ColorTokens.cherryPrimary : ColorTokens.bgSurfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Vintage Cams horizontal list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // "Original" card
                    let isNoneSelected = selectedPresetId == nil
                    PresetCard(
                        id: "none",
                        name: "Original",
                        isPro: false,
                        isSelected: isNoneSelected,
                        gradient: LinearGradient(
                            colors: [Color(hex: 0x222634), Color(hex: 0x141722)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        onClick: { onSelectPreset(nil) }
                    )

                    ForEach(filteredPresets) { preset in
                        let isSelected = preset.id == selectedPresetId
                        PresetCard(
                            id: preset.id,
                            name: preset.name,
                            isPro: preset.isPro,
                            isSelected: isSelected,
                            gradient: getCamGradient(presetId: preset.id),
                            onClick: {
                                if preset.isPro && !ProSubscriptionManager.shared.isPro {
                                    onRequirePro()
                                } else {
                                    onSelectPreset(preset)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 6)
            }
        }
    }

    private func getCamGradient(presetId: String) -> LinearGradient {
        switch presetId {
        case "digicam_01":
            return LinearGradient(
                colors: [Color(hex: 0xFFFF2D55), Color(hex: 0x4F46E5), Color(hex: 0x06B6D4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "portra_01":
            return LinearGradient(
                colors: [Color(hex: 0xFED7AA), Color(hex: 0xF472B6), Color(hex: 0xC084FC)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "dispo_01":
            return LinearGradient(
                colors: [Color(hex: 0xF97316), Color(hex: 0xEAB308), Color(hex: 0xDC2626)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "flash_01":
            return LinearGradient(
                colors: [Color.white, Color(hex: 0x94A3B8), Color(hex: 0x1E293B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "golden_01":
            return LinearGradient(
                colors: [Color(hex: 0xD97706), Color(hex: 0xB45309), Color(hex: 0xFEF3C7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "cyber_01":
            return LinearGradient(
                colors: [Color(hex: 0x06B6D4), Color(hex: 0xA855F7), Color(hex: 0xEC4899)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "noir_01":
            return LinearGradient(
                colors: [Color(hex: 0xF8FAFC), Color(hex: 0x64748B), Color(hex: 0x0F172A)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return ColorTokens.brandGradient
        }
    }
}

public struct PresetCard: View {
    public let id: String
    public let name: String
    public let isPro: Bool
    public let isSelected: Bool
    public let gradient: LinearGradient
    public let onClick: () -> Void

    public var body: some View {
        Button(action: onClick) {
            VStack(spacing: 0) {
                // Top Tag: Checkmark or PRO
                HStack {
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.cherryPrimary)
                                .frame(width: 15, height: 15)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Spacer().frame(width: 15)
                    }

                    Spacer()

                    if isPro {
                        Text("PRO")
                            .font(.system(size: 7.5, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(ColorTokens.proBadgeGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .frame(height: 16)

                Spacer()

                // Camera lens simulation preview
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))

                    if id == "none" {
                        Image(systemName: "circle.slash")
                            .font(.system(size: 20))
                            .foregroundColor(ColorTokens.textMuted)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()

                // Name
                Text(name)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? ColorTokens.textPrimary : ColorTokens.textSecondary)
                    .lineLimit(1)
            }
            .padding(6)
            .frame(width: 88, height: 116)
            .background(isSelected ? ColorTokens.bgSurfaceElevated : ColorTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
