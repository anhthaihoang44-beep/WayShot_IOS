import SwiftUI

public struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()

    @State private var selectedToolTab: ToolTab = .filters
    @State private var isExportDialogOpen: Bool = false
    @State private var isSplitActive: Bool = false
    @State private var splitPosition: Float = 0.5

    @State private var isCameraPresented: Bool = false
    @State private var isPhotoPickerPresented: Bool = false
    @State private var isShareSheetPresented: Bool = false
    @State private var isPaywallPresented: Bool = false
    @State private var shareURL: URL? = nil

    public init() {}

    public var body: some View {
        let uiState = viewModel.uiState

        ZStack {
            ColorTokens.bgDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Action Bar
                TopActionBar(
                    canUndo: uiState.canUndo,
                    canRedo: uiState.canRedo,
                    hasImage: uiState.rawImage != nil,
                    isSplitActive: isSplitActive,
                    onCloseImage: { viewModel.clearImage() },
                    onUndo: { viewModel.undo() },
                    onRedo: { viewModel.redo() },
                    onToggleSplit: {
                        isSplitActive.toggle()
                        if isSplitActive { splitPosition = 0.5 }
                    },
                    onCompareChange: { isComparing in
                        viewModel.setComparingOriginal(isComparing)
                    },
                    onExportClick: {
                        isExportDialogOpen = true
                    },
                    onOpenPaywall: {
                        isPaywallPresented = true
                    }
                )

                if let displayImage = (uiState.isComparingOriginal ? uiState.rawImage : uiState.renderedPreview) ?? uiState.rawImage {
                    // Photo Editing Canvas Area
                    GeometryReader { geometry in
                        let imageAspect = displayImage.size.width / displayImage.size.height
                        let containerWidth = geometry.size.width
                        let containerHeight = geometry.size.height

                        // Calculate fit-center aspect ratio dimensions
                        let fittedSize: CGSize = {
                            let containerAspect = containerWidth / containerHeight
                            if imageAspect > containerAspect {
                                let w = containerWidth
                                let h = containerWidth / imageAspect
                                return CGSize(width: w, height: h)
                            } else {
                                let h = containerHeight
                                let w = containerHeight * imageAspect
                                return CGSize(width: w, height: h)
                            }
                        }()

                        ZStack {
                            ColorTokens.bgCanvas
                                .ignoresSafeArea()

                            // Aspect-ratio-locked Canvas
                            ZStack {
                                if isSplitActive && !uiState.isComparingOriginal, let raw = uiState.rawImage {
                                    // Split View: Left side rendered, Right side raw
                                    ZStack {
                                        Image(uiImage: displayImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: fittedSize.width, height: fittedSize.height)

                                        // Raw image clipped to right side of split line
                                        Image(uiImage: raw)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: fittedSize.width, height: fittedSize.height)
                                            .clipShape(
                                                SplitClipShape(splitFraction: CGFloat(splitPosition))
                                            )

                                        // Interactive Draggable Split Divider Line & Handle
                                        InteractiveSplitSlider(
                                            splitPosition: $splitPosition,
                                            canvasWidth: fittedSize.width,
                                            canvasHeight: fittedSize.height
                                        )
                                    }
                                } else {
                                    Image(uiImage: displayImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: fittedSize.width, height: fittedSize.height)
                                }

                                // Comparing RAW indicator
                                if uiState.isComparingOriginal {
                                    VStack {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(ColorTokens.cherryPrimary)
                                                .frame(width: 6, height: 6)

                                            Text("VIEWING RAW ORIGINAL")
                                                .font(.system(size: 11, weight: .bold))
                                                .tracking(1)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.85))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTokens.borderSubtle, lineWidth: 1))
                                        .padding(.top, 16)

                                        Spacer()
                                    }
                                }

                                // Retro LED Date Stamp Simulation in Bottom Right
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text("'26 10 21")
                                            .font(TypographyTokens.monospacedDate)
                                            .foregroundColor(ColorTokens.retroOrange.opacity(0.85))
                                            .tracking(2)
                                            .padding(.trailing, 16)
                                            .padding(.bottom, 12)
                                    }
                                }

                                // Exporting loading spinner
                                if uiState.isExporting {
                                    ZStack {
                                        Color.black.opacity(0.75)
                                        VStack(spacing: 14) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: ColorTokens.cherryPrimary))
                                                .scaleEffect(1.2)

                                            Text(uiState.exportMessage ?? "Exporting...")
                                                .font(.system(size: 13.5, weight: .semibold))
                                                .foregroundColor(ColorTokens.textPrimary)
                                        }
                                    }
                                }
                            }
                            .frame(width: fittedSize.width, height: fittedSize.height)
                        }
                    }

                    // Bottom Editing Controls
                    VStack(spacing: 0) {
                        Group {
                            switch selectedToolTab {
                            case .filters:
                                PresetStrip(
                                    presets: uiState.presets,
                                    selectedPresetId: uiState.editState.selectedPresetId,
                                    presetIntensity: uiState.editState.presetIntensity,
                                    onSelectPreset: { viewModel.selectPreset($0) },
                                    onIntensityChange: { viewModel.setPresetIntensity($0) },
                                    onRequirePro: { isPaywallPresented = true }
                                )
                            case .adjust:
                                AdjustmentsPanel(
                                    adjustments: Binding(
                                        get: { uiState.editState.adjustments },
                                        set: { viewModel.updateAdjustments($0) }
                                    )
                                )
                            case .curves:
                                CurvesPanel(
                                    curves: Binding(
                                        get: { uiState.editState.curves },
                                        set: { viewModel.updateCurves($0) }
                                    ),
                                    onRequirePro: { isPaywallPresented = true }
                                )
                            case .hsl:
                                HslPanel(
                                    hsl: Binding(
                                        get: { uiState.editState.hsl },
                                        set: { viewModel.updateHsl($0) }
                                    ),
                                    onRequirePro: { isPaywallPresented = true }
                                )
                            case .effects:
                                EffectsPanel(
                                    effects: Binding(
                                        get: { uiState.editState.effects },
                                        set: { viewModel.updateEffects($0) }
                                    )
                                )
                            case .borderCrop:
                                BorderCropPanel(
                                    crop: Binding(
                                        get: { uiState.editState.crop },
                                        set: { viewModel.updateCrop($0) }
                                    ),
                                    border: Binding(
                                        get: { uiState.editState.border },
                                        set: { viewModel.updateBorder($0) }
                                    )
                                )
                            }
                        }
                        .padding(.vertical, 4)
                        .background(ColorTokens.bgDark)

                        // Bottom Navigation Bar
                        ToolNavigationBar(
                            selectedTab: selectedToolTab,
                            onTabSelected: { selectedToolTab = $0 }
                        )
                    }
                } else {
                    // Studio Home Screen
                    StudioHomeView(
                        presets: uiState.presets,
                        isExporting: uiState.isExporting,
                        exportMessage: uiState.exportMessage,
                        onTakePhoto: { isCameraPresented = true },
                        onPickImage: { isPhotoPickerPresented = true },
                        onTrySample: { presetId in
                            viewModel.loadSampleImage(initialPresetId: presetId)
                        }
                    )
                }
            }
        }
        // Export Dialog
        .overlay(
            ExportDialog(
                isPresented: isExportDialogOpen,
                onDismiss: { isExportDialogOpen = false },
                onConfirmExport: { format, quality, shouldShare in
                    viewModel.exportImage(format: format, quality: quality) { savedURL in
                        if shouldShare, let url = savedURL {
                            self.shareURL = url
                            self.isShareSheetPresented = true
                        }
                    }
                }
            )
        )
        // Camera sheet
        .sheet(isPresented: $isCameraPresented) {
            CameraPickerView(isPresented: $isCameraPresented) { image in
                viewModel.onImageSelected(image)
            }
        }
        // Photo Picker sheet
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoPickerView(isPresented: $isPhotoPickerPresented) { image in
                viewModel.onImageSelected(image)
            }
        }
        // Share sheet
        .sheet(isPresented: $isShareSheetPresented) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        // Pro Paywall sheet (ADR-007)
        .sheet(isPresented: $isPaywallPresented) {
            ProPaywallView(sourceTrigger: "editor_upgrade")
        }
    }
}

public struct SplitClipShape: Shape {
    public var splitFraction: CGFloat

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = rect.width * splitFraction
        path.addRect(CGRect(x: startX, y: 0, width: rect.width - startX, height: rect.height))
        return path
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
