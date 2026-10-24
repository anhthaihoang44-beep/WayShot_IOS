import Foundation

public struct EditState: Codable, Equatable {
    public var crop: CropTransform = CropTransform()
    public var adjustments: Adjustments = Adjustments()
    public var curves: Curves = Curves()
    public var hsl: HslAdjustment = HslAdjustment()
    public var selectedPresetId: String? = nil
    public var presetIntensity: Float = 1.0
    public var effects: Effects = Effects()
    public var border: Border = Border()

    public init(
        crop: CropTransform = CropTransform(),
        adjustments: Adjustments = Adjustments(),
        curves: Curves = Curves(),
        hsl: HslAdjustment = HslAdjustment(),
        selectedPresetId: String? = nil,
        presetIntensity: Float = 1.0,
        effects: Effects = Effects(),
        border: Border = Border()
    ) {
        self.crop = crop
        self.adjustments = adjustments
        self.curves = curves
        self.hsl = hsl
        self.selectedPresetId = selectedPresetId
        self.presetIntensity = presetIntensity
        self.effects = effects
        self.border = border
    }
}

public class EditSession {
    public private(set) var currentState: EditState
    private let maxHistoryDepth: Int

    private var undoStack: [EditState] = []
    private var redoStack: [EditState] = []

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public init(initialState: EditState = EditState(), maxHistoryDepth: Int = 30) {
        self.currentState = initialState
        self.maxHistoryDepth = maxHistoryDepth
    }

    public func pushState(_ newState: EditState) {
        if newState == currentState { return }
        undoStack.append(currentState)
        if undoStack.count > maxHistoryDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
        currentState = newState
    }

    @discardableResult
    public func undo() -> Bool {
        guard canUndo else { return false }
        let previousState = undoStack.removeLast()
        redoStack.append(currentState)
        currentState = previousState
        return true
    }

    @discardableResult
    public func redo() -> Bool {
        guard canRedo else { return false }
        let nextState = redoStack.removeLast()
        undoStack.append(currentState)
        currentState = nextState
        return true
    }

    public func reset() {
        pushState(EditState())
    }
}
