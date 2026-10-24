import SwiftUI

public struct InteractiveSplitSlider: View {
    @Binding public var splitPosition: Float
    public let canvasWidth: CGFloat
    public let canvasHeight: CGFloat

    public init(splitPosition: Binding<Float>, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        self._splitPosition = splitPosition
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
    }

    public var body: some View {
        let splitX = CGFloat(splitPosition) * canvasWidth

        ZStack {
            // Floating Before / After Badges
            VStack {
                HStack {
                    Text("AFTER")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(ColorTokens.cherryPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTokens.borderSubtle, lineWidth: 1))

                    Spacer()

                    Text("BEFORE")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(ColorTokens.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()
            }

            // Vertical crisp white divider line
            Rectangle()
                .fill(Color.white)
                .frame(width: 2)
                .position(x: splitX, y: canvasHeight / 2)

            // Draggable center handle
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(ColorTokens.cherryPrimary, lineWidth: 2.5))

                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            .position(x: splitX, y: canvasHeight / 2)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let newPos = Float(gesture.location.x / canvasWidth)
                        splitPosition = max(0.02, min(0.98, newPos))
                    }
            )
        }
    }
}
