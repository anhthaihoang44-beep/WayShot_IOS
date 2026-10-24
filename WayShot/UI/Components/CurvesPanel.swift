import SwiftUI

public enum CurveChannel: String, CaseIterable, Identifiable {
    case rgb = "RGB"
    case red = "Red"
    case green = "Green"
    case blue = "Blue"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .rgb: return .white
        case .red: return Color(hex: "#FF4565")
        case .green: return Color(hex: "#10B981")
        case .blue: return Color(hex: "#3B82F6")
        }
    }
}

public struct CurvesPanel: View {
    @Binding public var curves: Curves
    @State private var selectedChannel: CurveChannel = .rgb
    public let onRequirePro: () -> Void

    public init(curves: Binding<Curves>, onRequirePro: @escaping () -> Void = {}) {
        self._curves = curves
        self.onRequirePro = onRequirePro
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Channel Selector & Quick Presets
            HStack {
                HStack(spacing: 6) {
                    ForEach(CurveChannel.allCases) { channel in
                        let isSelected = channel == selectedChannel
                        Button(action: { selectedChannel = channel }) {
                            Text(channel.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .black : channel.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isSelected ? channel.color : ColorTokens.bgSurfaceElevated)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Quick presets
                HStack(spacing: 6) {
                    Button("S-Curve") {
                        applyPreset(type: .sCurve)
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(ColorTokens.cherryPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTokens.bgSurfaceElevated)
                    .clipShape(Capsule())

                    Button("Matte") {
                        applyPreset(type: .matte)
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(ColorTokens.retroOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTokens.bgSurfaceElevated)
                    .clipShape(Capsule())

                    Button("Reset") {
                        resetChannel()
                    }
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(ColorTokens.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 16)

            // Interactive Curve Canvas
            ZStack {
                ColorTokens.bgSurfaceElevated
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTokens.borderSubtle, lineWidth: 1))

                // Grid lines
                Path { path in
                    for i in 1...3 {
                        let fraction = CGFloat(i) / 4.0
                        path.move(to: CGPoint(x: fraction * 320, y: 0))
                        path.addLine(to: CGPoint(x: fraction * 320, y: 110))
                        path.move(to: CGPoint(x: 0, y: fraction * 110))
                        path.addLine(to: CGPoint(x: 320, y: fraction * 110))
                    }
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1)

                // The Curve Line
                CurvePath(points: currentPoints)
                    .stroke(selectedChannel.color, lineWidth: 2.5)

                // Control points dots
                GeometryReader { geo in
                    ForEach(0..<currentPoints.count, id: \.self) { idx in
                        let pt = currentPoints[idx]
                        Circle()
                            .fill(selectedChannel.color)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .position(
                                x: CGFloat(pt.x) * geo.size.width,
                                y: (1.0 - CGFloat(pt.y)) * geo.size.height
                            )
                    }
                }
            }
            .frame(height: 110)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 4)
    }

    private var currentPoints: [CurvePoint] {
        switch selectedChannel {
        case .rgb: return curves.rgb
        case .red: return curves.red
        case .green: return curves.green
        case .blue: return curves.blue
        }
    }

    private enum CurvePresetType {
        case sCurve
        case matte
    }

    private func applyPreset(type: CurvePresetType) {
        if !ProSubscriptionManager.shared.isPro {
            onRequirePro()
            return
        }

        let newPoints: [CurvePoint]
        switch type {
        case .sCurve:
            newPoints = [
                CurvePoint(x: 0.0, y: 0.0),
                CurvePoint(x: 0.25, y: 0.18),
                CurvePoint(x: 0.75, y: 0.82),
                CurvePoint(x: 1.0, y: 1.0)
            ]
        case .matte:
            newPoints = [
                CurvePoint(x: 0.0, y: 0.10),
                CurvePoint(x: 0.5, y: 0.50),
                CurvePoint(x: 1.0, y: 0.92)
            ]
        }

        updateCurrentChannel(points: newPoints)
    }

    private func resetChannel() {
        let linear = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
        updateCurrentChannel(points: linear)
    }

    private func updateCurrentChannel(points: [CurvePoint]) {
        switch selectedChannel {
        case .rgb: curves.rgb = points
        case .red: curves.red = points
        case .green: curves.green = points
        case .blue: curves.blue = points
        }
    }
}

public struct CurvePath: Shape {
    public let points: [CurvePoint]

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }

        let first = points[0]
        path.move(to: CGPoint(x: CGFloat(first.x) * rect.width, y: (1.0 - CGFloat(first.y)) * rect.height))

        for i in 1..<points.count {
            let pt = points[i]
            path.addLine(to: CGPoint(x: CGFloat(pt.x) * rect.width, y: (1.0 - CGFloat(pt.y)) * rect.height))
        }

        return path
    }
}
