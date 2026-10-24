import SwiftUI
import Combine

public struct EditorUiState {
    public var rawImage: UIImage? = nil
    public var renderedPreview: UIImage? = nil
    public var presets: [Preset] = []
    public var selectedPreset: Preset? = nil
    public var editState: EditState = EditState()
    public var canUndo: Bool = false
    public var canRedo: Bool = false
    public var isComparingOriginal: Bool = false
    public var isExporting: Bool = false
    public var exportMessage: String? = nil
    public var exportedURL: URL? = nil

    public init() {}
}

@MainActor
public final class EditorViewModel: ObservableObject {

    @Published public private(set) var uiState = EditorUiState()

    private let presetRepository: PresetRepository = PresetRepositoryImpl()
    private let editSession = EditSession()
    private var renderTask: Task<Void, Never>? = nil

    public init() {
        loadPresets()
    }

    public func loadPresets() {
        Task {
            do {
                let presets = try await presetRepository.getPresets()
                self.uiState.presets = presets
            } catch {
                print("Failed to load presets: \(error)")
                PrivacyCompliantAnalyticsService.shared.logError(
                    errorDescription: error.localizedDescription,
                    domain: "PresetRepository"
                )
            }
        }
    }

    public func onImageSelected(_ image: UIImage) {
        let downsampled = ImageIOHelper.downsample(image: image, maxDimension: 1440)
        editSession.reset()

        uiState.rawImage = downsampled
        uiState.editState = editSession.currentState
        uiState.selectedPreset = nil
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo
        uiState.exportMessage = nil

        triggerRenderPreview()
    }

    public func loadSampleImage(initialPresetId: String? = nil) {
        uiState.isExporting = true
        uiState.exportMessage = "Loading sample photo..."

        let sample = SampleImageGenerator.generateAestheticSampleImage(width: 1080, height: 1350)
        editSession.reset()

        let initialPreset = initialPresetId != nil ? uiState.presets.first(where: { $0.id == initialPresetId }) : nil
        if let preset = initialPreset {
            let stateWithPreset = EditState(
                crop: editSession.currentState.crop,
                adjustments: editSession.currentState.adjustments,
                curves: editSession.currentState.curves,
                hsl: editSession.currentState.hsl,
                selectedPresetId: preset.id,
                presetIntensity: preset.defaultIntensity,
                effects: editSession.currentState.effects,
                border: editSession.currentState.border
            )
            editSession.pushState(stateWithPreset)
        }

        uiState.rawImage = sample
        uiState.editState = editSession.currentState
        uiState.selectedPreset = initialPreset
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo
        uiState.isExporting = false
        uiState.exportMessage = nil

        triggerRenderPreview()
    }

    public func clearImage() {
        editSession.reset()
        uiState.rawImage = nil
        uiState.renderedPreview = nil
        uiState.selectedPreset = nil
        uiState.editState = editSession.currentState
        uiState.canUndo = false
        uiState.canRedo = false
        uiState.isComparingOriginal = false
        uiState.exportMessage = nil
        uiState.exportedURL = nil
    }

    public func selectPreset(_ preset: Preset?) {
        var newState = editSession.currentState
        newState.selectedPresetId = preset?.id
        newState.presetIntensity = preset?.defaultIntensity ?? 1.0
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.selectedPreset = preset
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        if let p = preset {
            PrivacyCompliantAnalyticsService.shared.logPresetSelected(presetId: p.id, isPro: p.isPro)
        }

        triggerRenderPreview()
    }

    public func setPresetIntensity(_ intensity: Float) {
        var newState = editSession.currentState
        newState.presetIntensity = intensity
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func updateAdjustments(_ adjustments: Adjustments) {
        var newState = editSession.currentState
        newState.adjustments = adjustments
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func updateCurves(_ curves: Curves) {
        var newState = editSession.currentState
        newState.curves = curves
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func updateHsl(_ hsl: HslAdjustment) {
        var newState = editSession.currentState
        newState.hsl = hsl
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func updateEffects(_ effects: Effects) {
        var newState = editSession.currentState
        newState.effects = effects
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func updateBorder(_ border: Border) {
        var newState = editSession.currentState
        newState.border = border
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func updateCrop(_ crop: CropTransform) {
        var newState = editSession.currentState
        newState.crop = crop
        editSession.pushState(newState)

        uiState.editState = newState
        uiState.canUndo = editSession.canUndo
        uiState.canRedo = editSession.canRedo

        triggerRenderPreview()
    }

    public func undo() {
        if editSession.undo() {
            let state = editSession.currentState
            let preset = uiState.presets.first(where: { $0.id == state.selectedPresetId })
            uiState.editState = state
            uiState.selectedPreset = preset
            uiState.canUndo = editSession.canUndo
            uiState.canRedo = editSession.canRedo

            triggerRenderPreview()
        }
    }

    public func redo() {
        if editSession.redo() {
            let state = editSession.currentState
            let preset = uiState.presets.first(where: { $0.id == state.selectedPresetId })
            uiState.editState = state
            uiState.selectedPreset = preset
            uiState.canUndo = editSession.canUndo
            uiState.canRedo = editSession.canRedo

            triggerRenderPreview()
        }
    }

    public func setComparingOriginal(_ isComparing: Bool) {
        uiState.isComparingOriginal = isComparing
    }

    private func triggerRenderPreview() {
        guard let raw = uiState.rawImage else { return }
        let state = uiState.editState
        let preset = uiState.selectedPreset

        renderTask?.cancel()
        renderTask = Task {
            let rendered = await Task.detached(priority: .userInitiated) {
                WayShotCoreImagePipeline.shared.render(
                    image: raw,
                    state: state,
                    preset: preset,
                    isComparingOriginal: false,
                    splitPosition: -1.0
                )
            }.value

            if !Task.isCancelled {
                self.uiState.renderedPreview = rendered
            }
        }
    }

    public func exportImage(
        format: ExportFormat,
        quality: Float,
        onComplete: @escaping (URL?) -> Void
    ) {
        guard let source = uiState.rawImage else { return }

        uiState.isExporting = true
        uiState.exportMessage = "Rendering high-resolution image..."

        let startTime = Date()
        PrivacyCompliantAnalyticsService.shared.logExportStarted(
            format: format.label,
            isProFeature: quality >= 1.0
        )

        Task {
            let state = self.uiState.editState
            let preset = self.uiState.selectedPreset

            let rendered = await HeadlessImageExporter.renderFullResolution(
                sourceImage: source,
                state: state,
                preset: preset
            )

            do {
                let savedURL = try await PhotoLibrarySaver.saveImageToGallery(
                    image: rendered,
                    format: format,
                    quality: quality
                )

                let duration = Date().timeIntervalSince(startTime)
                PrivacyCompliantAnalyticsService.shared.logExportCompleted(
                    format: format.label,
                    durationSeconds: duration,
                    success: true
                )

                self.uiState.isExporting = false
                self.uiState.exportedURL = savedURL
                self.uiState.exportMessage = "Saved successfully to Photos/WayShot!"
                onComplete(savedURL)
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                PrivacyCompliantAnalyticsService.shared.logExportCompleted(
                    format: format.label,
                    durationSeconds: duration,
                    success: false
                )
                PrivacyCompliantAnalyticsService.shared.logError(
                    errorDescription: error.localizedDescription,
                    domain: "PhotoExport"
                )

                self.uiState.isExporting = false
                self.uiState.exportMessage = "Export failed: \(error.localizedDescription)"
                onComplete(nil)
            }
        }
    }
}
