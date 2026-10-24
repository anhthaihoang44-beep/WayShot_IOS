import SwiftUI

public struct StudioHomeView: View {
    public let presets: [Preset]
    public let isExporting: Bool
    public let exportMessage: String?
    public let onTakePhoto: () -> Void
    public let onPickImage: () -> Void
    public let onTrySample: (String?) -> Void

    public init(
        presets: [Preset],
        isExporting: Bool,
        exportMessage: String?,
        onTakePhoto: @escaping () -> Void,
        onPickImage: @escaping () -> Void,
        onTrySample: @escaping (String?) -> Void
    ) {
        self.presets = presets
        self.isExporting = isExporting
        self.exportMessage = exportMessage
        self.onTakePhoto = onTakePhoto
        self.onPickImage = onPickImage
        self.onTrySample = onTrySample
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                // Hero Intro Card
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ColorTokens.brandGradient)
                            .frame(width: 62, height: 62)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 4) {
                        Text("Aesthetic DigiCam & Film")
                            .font(TypographyTokens.headline)
                            .foregroundColor(ColorTokens.textPrimary)

                        Text("Shoot & create 35mm film tones, Y2K digicam & vintage aesthetics")
                            .font(TypographyTokens.body)
                            .foregroundColor(ColorTokens.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .background(ColorTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(ColorTokens.borderSubtle, lineWidth: 1))

                // Primary Action 1: Take Photo
                Button(action: onTakePhoto) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 46, height: 46)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Take Photo")
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(.white)

                            Text("Shoot live with retro camera tones")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(ColorTokens.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                // Primary Action 2: Choose from Gallery
                Button(action: onPickImage) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.bgSurface)
                                .frame(width: 46, height: 46)

                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(ColorTokens.cherryPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open from Gallery")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(ColorTokens.textPrimary)

                            Text("Choose existing photo to grade & add effects")
                                .font(.system(size: 12))
                                .foregroundColor(ColorTokens.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(ColorTokens.bgSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                }

                // Quick Action: Try aesthetic sample shot
                Button(action: { onTrySample(nil) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ColorTokens.cherryPrimary)

                        Text("✨ Try with aesthetic sample photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ColorTokens.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(ColorTokens.bgSurfaceElevated.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                }

                // Featured Cameras / Presets Showcase Section
                if !presets.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("FEATURED FILM TONES & AESTHETICS")
                                .font(.system(size: 11.5, weight: .bold))
                                .tracking(1)
                                .foregroundColor(ColorTokens.textSecondary)

                            Spacer()

                            Text("\(presets.count) Cams")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ColorTokens.cherryPrimary)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(presets) { preset in
                                    Button(action: { onTrySample(preset.id) }) {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(getCamGradient(presetId: preset.id))
                                                    .frame(width: 42, height: 42)

                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.white)
                                            }

                                            Text(preset.name)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(ColorTokens.textPrimary)
                                                .lineLimit(1)

                                            Text(preset.category)
                                                .font(.system(size: 9.5, weight: .medium))
                                                .foregroundColor(ColorTokens.textMuted)
                                        }
                                        .frame(width: 120)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(ColorTokens.bgSurfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
