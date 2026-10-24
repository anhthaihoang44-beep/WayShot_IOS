import SwiftUI
import StoreKit

public struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var proManager = ProSubscriptionManager.shared

    @State private var selectedPlan: ProProduct = .yearly
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    public let sourceTrigger: String

    public init(sourceTrigger: String = "general") {
        self.sourceTrigger = sourceTrigger
    }

    public var body: some View {
        ZStack {
            ColorTokens.bgDark
                .ignoresSafeArea()

            // Ambient background glow
            VStack {
                Circle()
                    .fill(ColorTokens.cherryPrimary.opacity(0.25))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(ColorTokens.textMuted)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Hero Header
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(ColorTokens.retroOrange)

                            Text("WAYSHOT PRO STUDIO")
                                .font(.system(size: 13, weight: .black))
                                .tracking(2)
                                .foregroundColor(ColorTokens.retroOrange)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(ColorTokens.retroOrange.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(ColorTokens.retroOrange.opacity(0.3), lineWidth: 1))

                        Text("Unlock Ultimate Film & DigiCam Aesthetics")
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(ColorTokens.textPrimary)
                            .padding(.horizontal, 24)

                        Text("Experience 100% on-device GPU acceleration with master tone curves, full preset library and uncompressed 4K export.")
                            .font(.system(size: 13.5))
                            .multilineTextAlignment(.center)
                            .foregroundColor(ColorTokens.textSecondary)
                            .padding(.horizontal, 32)
                    }

                    // Feature List
                    VStack(spacing: 14) {
                        featureRow(
                            icon: "camera.filters",
                            title: "All 20+ Vintage Presets",
                            subtitle: "Unlock Portra 400, Digi-Cam 2000, Night Flash & Cyber Y2K"
                        )
                        featureRow(
                            icon: "waveform.path",
                            title: "Pro Tone Curves & 8-Band HSL",
                            subtitle: "Individual RGB channels and fine-grained color grading"
                        )
                        featureRow(
                            icon: "sparkles.tv",
                            title: "Vintage Effects & Film Frames",
                            subtitle: "Authentic 35mm sprocket borders, VHS glitch & prism chromatic"
                        )
                        featureRow(
                            icon: "arrow.up.forward.app.fill",
                            title: "4K Full-Resolution Export",
                            subtitle: "Export original uncompressed images without watermark"
                        )
                    }
                    .padding(.horizontal, 24)

                    // Plan Selection Cards
                    VStack(spacing: 12) {
                        planCard(
                            plan: .yearly,
                            badge: "BEST VALUE — 7-DAY FREE TRIAL",
                            title: "Annual Membership",
                            price: "$19.99 / year",
                            footnote: "Just $1.66 / month. Cancel anytime."
                        )

                        planCard(
                            plan: .lifetime,
                            badge: "ONE-TIME PURCHASE",
                            title: "Lifetime Access",
                            price: "$39.99",
                            footnote: "Pay once, own all future updates forever."
                        )
                    }
                    .padding(.horizontal, 20)

                    // Action CTA Button
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await handlePurchase()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [ColorTokens.cherryPrimary, Color(hex: "#FF4565")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: ColorTokens.cherryPrimary.opacity(0.4), radius: 12, y: 4)

                                if proManager.isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    HStack {
                                        Text(selectedPlan == .yearly ? "START 7-DAY FREE TRIAL" : "UNLOCK LIFETIME ACCESS")
                                            .font(.system(size: 15, weight: .bold))
                                            .tracking(1)
                                            .foregroundColor(.white)

                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(height: 54)
                        }
                        .disabled(proManager.isPurchasing)

                        // Secondary actions: Restore Purchases
                        Button(action: {
                            Task {
                                do {
                                    try await proManager.restorePurchases()
                                    if proManager.isPro {
                                        dismiss()
                                    }
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingErrorAlert = true
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(ColorTokens.textMuted)
                        }
                        .padding(.top, 4)

                        // Privacy & Terms
                        Text("Payment will be charged to your Apple ID account upon purchase confirmation. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.")
                            .font(.system(size: 10))
                            .foregroundColor(ColorTokens.textMuted.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Notice"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorTokens.cherryPrimary.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorTokens.cherryPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(ColorTokens.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(ColorTokens.textMuted)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func planCard(
        plan: ProProduct,
        badge: String,
        title: String,
        price: String,
        footnote: String
    ) -> some View {
        let isSelected = selectedPlan == plan

        Button(action: { selectedPlan = plan }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? ColorTokens.bgCard : ColorTokens.bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? ColorTokens.cherryPrimary : ColorTokens.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(badge)
                            .font(.system(size: 9.5, weight: .bold))
                            .tracking(1)
                            .foregroundColor(isSelected ? ColorTokens.cherryPrimary : ColorTokens.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((isSelected ? ColorTokens.cherryPrimary : ColorTokens.textMuted).opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? ColorTokens.cherryPrimary : ColorTokens.textMuted)
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ColorTokens.textPrimary)

                        Spacer()

                        Text(price)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ColorTokens.textPrimary)
                    }

                    Text(footnote)
                        .font(.system(size: 12))
                        .foregroundColor(ColorTokens.textSecondary)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }

    private func handlePurchase() async {
        // Try to match real product from StoreKit
        if let product = proManager.availableProducts.first(where: { $0.id == selectedPlan.rawValue }) {
            do {
                let success = try await proManager.purchase(product: product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        } else {
            // Simulator / Debug Mode unlock
            proManager.setDebugProStatus(true)
            dismiss()
        }
    }
}
