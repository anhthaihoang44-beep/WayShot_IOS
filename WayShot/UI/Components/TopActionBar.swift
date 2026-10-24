import SwiftUI

public struct TopActionBar: View {
    public let canUndo: Bool
    public let canRedo: Bool
    public let hasImage: Bool
    public let isSplitActive: Bool

    public let onCloseImage: () -> Void
    public let onUndo: () -> Void
    public let onRedo: () -> Void
    public let onToggleSplit: () -> Void
    public let onCompareChange: (Bool) -> Void
    public let onExportClick: () -> Void
    public let onOpenPaywall: () -> Void

    @ObservedObject private var proManager = ProSubscriptionManager.shared
    @State private var isComparingPressed: Bool = false

    public init(
        canUndo: Bool,
        canRedo: Bool,
        hasImage: Bool,
        isSplitActive: Bool,
        onCloseImage: @escaping () -> Void,
        onUndo: @escaping () -> Void,
        onRedo: @escaping () -> Void,
        onToggleSplit: @escaping () -> Void,
        onCompareChange: @escaping (Bool) -> Void,
        onExportClick: @escaping () -> Void,
        onOpenPaywall: @escaping () -> Void = {}
    ) {
        self.canUndo = canUndo
        self.canRedo = canRedo
        self.hasImage = hasImage
        self.isSplitActive = isSplitActive
        self.onCloseImage = onCloseImage
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onToggleSplit = onToggleSplit
        self.onCompareChange = onCompareChange
        self.onExportClick = onExportClick
        self.onOpenPaywall = onOpenPaywall
    }

    public var body: some View {
        ZStack {
            ColorTokens.bgDark
                .ignoresSafeArea(edges: .top)

            HStack(spacing: 8) {
                if hasImage {
                    // Close / Back button to return to Studio Home
                    Button(action: onCloseImage) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ColorTokens.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(ColorTokens.bgSurfaceElevated)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ColorTokens.borderSubtle, lineWidth: 1))
                    }
                } else {
                    // App Brand Header on Left
                    HStack(spacing: 9) {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.brandGradient)
                                .frame(width: 30, height: 30)

                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("WAYSHOT")
                                .font(.system(size: 14.5, weight: .black))
                                .tracking(2)
                                .foregroundColor(ColorTokens.textPrimary)

                            Text("Aesthetic Film & DigiCam")
                                .font(.system(size: 9, weight: .medium))
                                .tracking(0.4)
                                .foregroundColor(ColorTokens.textMuted)
                        }
                    }
                }

                Spacer()

                if hasImage {
                    // Center Editing Capsule
                    HStack(spacing: 4) {
                        // Undo
                        Button(action: onUndo) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(canUndo ? ColorTokens.textPrimary : ColorTokens.textMuted.opacity(0.35))
                                .frame(width: 28, height: 28)
                        }
                        .disabled(!canUndo)

                        // Split Toggle
                        Button(action: onToggleSplit) {
                            HStack(spacing: 3) {
                                Image(systemName: "slider.horizontal.2")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Split")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(isSplitActive ? .white : ColorTokens.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(isSplitActive ? ColorTokens.cherryPrimary : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // RAW hold-to-compare button
                        HStack(spacing: 3) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("RAW")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(isComparingPressed ? .white : ColorTokens.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isComparingPressed ? ColorTokens.cherryPrimary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isComparingPressed {
                                        isComparingPressed = true
                                        onCompareChange(true)
                                    }
                                }
                                .onEnded { _ in
                                    isComparingPressed = false
                                    onCompareChange(false)
                                }
                        )

                        // Redo
                        Button(action: onRedo) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(canRedo ? ColorTokens.textPrimary : ColorTokens.textMuted.opacity(0.35))
                                .frame(width: 28, height: 28)
                        }
                        .disabled(!canRedo)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(ColorTokens.bgSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTokens.borderSubtle, lineWidth: 1))

                    Spacer()

                    // PRO Badge or Crown
                    Button(action: onOpenPaywall) {
                        HStack(spacing: 4) {
                            Image(systemName: proManager.isPro ? "crown.fill" : "crown")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ColorTokens.retroOrange)

                            Text(proManager.isPro ? "PRO" : "GET PRO")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundColor(proManager.isPro ? ColorTokens.retroOrange : .white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(ColorTokens.bgSurfaceElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(ColorTokens.retroOrange.opacity(0.4), lineWidth: 1))
                    }

                    // Right Export Button
                    Button(action: onExportClick) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Export")
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(ColorTokens.brandGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    // Home Screen Right Badge
                    Button(action: onOpenPaywall) {
                        HStack(spacing: 5) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundColor(ColorTokens.retroOrange)

                            Text(proManager.isPro ? "PRO ACTIVE" : "PRO STUDIO")
                                .font(TypographyTokens.micro)
                                .tracking(0.8)
                                .foregroundColor(proManager.isPro ? ColorTokens.retroOrange : ColorTokens.cherryPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(ColorTokens.bgSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
        }
        .frame(height: 52)
    }
}
