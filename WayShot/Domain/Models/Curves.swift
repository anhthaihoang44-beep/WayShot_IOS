import Foundation

public struct CurvePoint: Codable, Equatable {
    public var x: Float // 0.0 to 1.0
    public var y: Float // 0.0 to 1.0

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public struct Curves: Codable, Equatable {
    public var rgb: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
    public var red: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
    public var green: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
    public var blue: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]

    public init(
        rgb: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)],
        red: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)],
        green: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)],
        blue: [CurvePoint] = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
    ) {
        self.rgb = rgb
        self.red = red
        self.green = green
        self.blue = blue
    }

    public func isLinear() -> Bool {
        return isChannelLinear(rgb) && isChannelLinear(red) &&
            isChannelLinear(green) && isChannelLinear(blue)
    }

    private func isChannelLinear(_ points: [CurvePoint]) -> Bool {
        guard points.count == 2 else { return false }
        return points[0].x == 0 && points[0].y == 0 &&
            points[1].x == 1 && points[1].y == 1
    }
}
