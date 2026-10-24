import SwiftUI

public struct ExportDialog: View {
    public let isPresented: Bool
    public let onDismiss: () -> Void
    public let onConfirmExport: (ExportFormat, Float, Bool) -> Void

    @State private var selectedFormat: ExportFormat = .jpeg
    @State private var selectedQuality: Float = 0.95

    public init(
        isPresented: Bool,
        onDismiss: @escaping () -> Void,
        onConfirmExport: @escaping (ExportFormat, Float, Bool) -> Void
    ) {
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.onConfirmExport = onConfirmExport
    }

    public var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Export High Resolution")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ColorTokens.textPrimary)

                    Text("Image will be rendered at full camera resolution via GPU and saved to Photos/WayShot.")
                        .font(.system(size: 12))
                        .foregroundColor(ColorTokens.textSecondary)
                        .lineSpacing(4)

                    // Format selector
                    Text("FILE FORMAT")
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(1)
                        .foregroundColor(ColorTokens.textMuted)

                    HStack(spacing: 8) {
                        ForEach(ExportFormat.allCases) { fmt in
                            let isSelected = selectedFormat == fmt
                            Button(action: { selectedFormat = fmt }) {
                                VStack(spacing: 2) {
                                    Text(fmt.label)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isSelected ? .white : ColorTokens.textPrimary)
                                    Text(fmt.subtitle)
                                        .font(.system(size: 10))
                                        .foregroundColor(isSelected ? .white.opacity(0.85) : ColorTokens.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? ColorTokens.cherryPrimary : ColorTokens.bgSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Quality selector (for JPEG)
                    if selectedFormat == .jpeg {
                        Text("QUALITY")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(1)
                            .foregroundColor(ColorTokens.textMuted)

                        HStack(spacing: 8) {
                            let qualities: [(Float, String, String)] = [
                                (1.00, "100%", "Ultra"),
                                (0.95, "95%", "Best"),
                                (0.85, "85%", "Compact")
                            ]
                            ForEach(qualities, id: \.1) { q, title, sub in
                                let isSelected = abs(selectedQuality - q) < 0.01
                                Button(action: { selectedQuality = q }) {
                                    VStack(spacing: 2) {
                                        Text(title)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(isSelected ? .white : ColorTokens.textPrimary)
                                        Text(sub)
                                            .font(.system(size: 10))
                                            .foregroundColor(isSelected ? .white.opacity(0.85) : ColorTokens.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? ColorTokens.cherryPrimary : ColorTokens.bgSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ColorTokens.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }

                        Button(action: {
                            onConfirmExport(selectedFormat, selectedQuality, true)
                            onDismiss()
                        }) {
                            Text("Share")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ColorTokens.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(ColorTokens.bgSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                        }

                        Button(action: {
                            onConfirmExport(selectedFormat, selectedQuality, false)
                            onDismiss()
                        }) {
                            Text("Save to Photos")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(ColorTokens.brandGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(ColorTokens.bgSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)
            }
        }
    }
}
