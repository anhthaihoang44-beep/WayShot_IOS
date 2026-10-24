import MetalKit
import SwiftUI
import simd

/// Memory layout matching `Uniforms` in WayShotShaders.metal
public struct MetalUniforms {
    public var brightness: Float = 0.0
    public var contrast: Float = 1.0
    public var saturation: Float = 1.0
    public var warmth: Float = 0.0
    public var highlights: Float = 0.0
    public var shadows: Float = 0.0
    public var sharpen: Float = 0.0

    public var hasPreset: Int32 = 0
    public var presetIntensity: Float = 1.0
    public var presetSaturation: Float = 0.0
    public var presetContrast: Float = 0.0
    public var presetWarmth: Float = 0.0
    public var presetFade: Float = 0.0
    public var presetShadowTint: (Float, Float, Float) = (0.0, 0.0, 0.0)
    public var presetHighlightTint: (Float, Float, Float) = (0.0, 0.0, 0.0)
    public var presetGrain: Float = 0.0

    public var grainIntensity: Float = 0.0
    public var chromaIntensity: Float = 0.0
    public var vhsIntensity: Float = 0.0

    public var borderType: Int32 = 0
    public var borderWidth: Float = 0.0
    public var splitX: Float = -1.0
    public var isComparingOriginal: Int32 = 0
    public var texelSize: SIMD2<Float> = SIMD2<Float>(1.0 / 1080.0, 1.0 / 1440.0)

    public init() {}
}

public final class WayShotMetalRenderer: NSObject, MTKViewDelegate {

    public var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var samplerState: MTLSamplerState?

    private var currentTexture: MTLTexture?
    private let textureLoader: MTKTextureLoader

    public var state: EditState = EditState()
    public var preset: Preset? = nil
    public var isComparingOriginal: Bool = false
    public var splitPosition: Float = -1.0

    private var vertexBuffer: MTLBuffer?
    private var texCoordBuffer: MTLBuffer?

    public init?(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.textureLoader = MTKTextureLoader(device: device)
        super.init()

        setupPipeline()
        setupBuffers()
    }

    private func setupBuffers() {
        guard let device = device else { return }
        let vertices: [Float] = [
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
             1.0,  1.0
        ]
        let texCoords: [Float] = [
            0.0, 1.0,
            1.0, 1.0,
            0.0, 0.0,
            1.0, 0.0
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.stride, options: [])
        texCoordBuffer = device.makeBuffer(bytes: texCoords, length: texCoords.count * MemoryLayout<Float>.stride, options: [])
    }

    private func setupPipeline() {
        guard let device = device else { return }

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor)

        guard let defaultLibrary = device.makeDefaultLibrary(),
              let vertexFunc = defaultLibrary.makeFunction(name: "vertexShader"),
              let fragmentFunc = defaultLibrary.makeFunction(name: "fragmentShader") else {
            return
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }

    public func setSourceImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        do {
            self.currentTexture = try textureLoader.newTexture(cgImage: cgImage, options: [
                .SRGB: false,
                .generateMipmaps: false
            ])
        } catch {
            print("Failed to load texture: \(error)")
        }
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDesc = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState,
              let texture = currentTexture,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else {
            return
        }

        var uniforms = MetalUniforms()
        let adj = state.adjustments
        uniforms.brightness = adj.brightness / 250.0
        uniforms.contrast = 1.0 + adj.contrast / 100.0
        uniforms.saturation = 1.0 + adj.saturation / 100.0
        uniforms.warmth = adj.warmth / 500.0
        uniforms.highlights = adj.highlights / 300.0
        uniforms.shadows = adj.shadows / 300.0
        uniforms.sharpen = adj.sharpen / 100.0

        if let p = preset, state.presetIntensity > 0.001 {
            uniforms.hasPreset = 1
            uniforms.presetIntensity = state.presetIntensity
            uniforms.presetSaturation = p.saturation
            uniforms.presetContrast = p.contrast
            uniforms.presetWarmth = p.warmth
            uniforms.presetFade = p.fade
            let sTint = p.shadowTint
            uniforms.presetShadowTint = (
                sTint.indices.contains(0) ? sTint[0] : 0,
                sTint.indices.contains(1) ? sTint[1] : 0,
                sTint.indices.contains(2) ? sTint[2] : 0
            )
            let hTint = p.highlightTint
            uniforms.presetHighlightTint = (
                hTint.indices.contains(0) ? hTint[0] : 0,
                hTint.indices.contains(1) ? hTint[1] : 0,
                hTint.indices.contains(2) ? hTint[2] : 0
            )
            uniforms.presetGrain = p.grain
        } else {
            uniforms.hasPreset = 0
        }

        uniforms.grainIntensity = state.effects.grain / 100.0
        uniforms.chromaIntensity = state.effects.chroma / 100.0
        uniforms.vhsIntensity = state.effects.vhs / 100.0

        switch state.border.type {
        case .none: uniforms.borderType = 0
        case .polaroid: uniforms.borderType = 1
        case .filmStrip: uniforms.borderType = 2
        case .minimalWhite: uniforms.borderType = 3
        case .minimalBlack: uniforms.borderType = 4
        }
        uniforms.borderWidth = state.border.widthPercent
        uniforms.splitX = splitPosition
        uniforms.isComparingOriginal = isComparingOriginal ? 1 : 0
        uniforms.texelSize = SIMD2<Float>(1.0 / Float(texture.width), 1.0 / Float(texture.height))

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 0)

        // Draw quad
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
