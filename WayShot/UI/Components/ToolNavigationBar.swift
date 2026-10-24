import SwiftUI

public enum ToolTab: String, CaseIterable, Identifiable {
    case filters = "Filters"
    case adjust = "Adjust"
    case curves = "Curves"
    case hsl = "HSL"
    case effects = "Effects"
    case borderCrop = "Frames"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .filters: return "camera.filters"
        case .adjust: return "slider.vertical.3"
        case .curves: return "waveform.path"
        case .hsl: return "paintpalette.fill"
        case .effects: return "sparkles"
        case .borderCrop: return "crop"
        }
    }
}

public struct ToolNavigationBar: View {
    public let selectedTab: ToolTab
    public let onTabSelected: (ToolTab) -> Void

    public init(selectedTab: ToolTab, onTabSelected: @escaping (ToolTab) -> Void) {
        self.selectedTab = selectedTab
        self.onTabSelected = onTabSelected
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top thin separator
            Divider()
                .background(ColorTokens.borderSubtle)

            HStack(spacing: 2) {
                ForEach(ToolTab.allCases) { tab in
                    let isSelected = tab == selectedTab

                    Button(action: { onTabSelected(tab) }) {
                        VStack(spacing: 3) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? ColorTokens.cherryPrimary.opacity(0.16) : Color.clear)
                                    .frame(width: 42, height: 26)

                                Image(systemName: tab.systemIcon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isSelected ? ColorTokens.cherryPrimary : ColorTokens.textMuted)
                            }

                            Text(tab.rawValue)
                                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : ColorTokens.textSecondary)

                            // Active dot indicator
                            Circle()
                                .fill(isSelected ? ColorTokens.cherryPrimary : Color.clear)
                                .frame(width: 3, height: 3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .background(ColorTokens.bgDark)
        }
    }
}
