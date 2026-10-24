#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float2 position  [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float2 texCoords;
};

struct Uniforms {
    // Basic Adjustments
    float brightness;   // b / 250.0
    float contrast;     // 1.0 + c / 100.0
    float saturation;   // 1.0 + s / 100.0
    float warmth;       // w / 500.0
    float highlights;   // h / 300.0
    float shadows;      // s / 300.0
    float sharpen;      // 0.0 to 1.0

    // Preset Filter
    int hasPreset;
    float presetIntensity;
    float presetSaturation;
    float presetContrast;
    float presetWarmth;
    float presetFade;
    packed_float3 presetShadowTint;
    packed_float3 presetHighlightTint;
    float presetGrain;

    // Effects
    float grainIntensity;
    float chromaIntensity;
    float vhsIntensity;

    // Border
    int borderType;     // 0: None, 1: Polaroid, 2: Film Strip, 3: White, 4: Black
    float borderWidth;

    // Interactive Before / After Split Slider (-1.0 = disabled, 0.0..1.0 = split position)
    float splitX;

    // Is comparing original
    int isComparingOriginal;

    float2 texelSize;
};

vertex VertexOutput vertexShader(uint vertexID [[vertex_id]],
                                 constant float2 *positions [[buffer(0)]],
                                 constant float2 *texCoords [[buffer(1)]]) {
    VertexOutput out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoords = texCoords[vertexID];
    return out;
}

// Rec.709 sRGB Luma
static float getLuma(float3 color) {
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

// Pseudo-random noise
static float randNoise(float2 co) {
    return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

fragment float4 fragmentShader(VertexOutput in [[stage_in]],
                               texture2d<float, access::sample> uTexture [[texture(0)]],
                               sampler uSampler [[sampler(0)]],
                               constant Uniforms &u [[buffer(0)]]) {
    float2 uv = in.texCoords;

    if (u.isComparingOriginal == 1) {
        return uTexture.sample(uSampler, uv);
    }

    // 1. Chroma / Prism effect (radial RGB separation)
    float4 baseColor;
    if (u.chromaIntensity > 0.001) {
        float2 dir = uv - 0.5;
        float dist = length(dir);
        float offset = u.chromaIntensity * 0.015 * dist;
        float r = uTexture.sample(uSampler, uv + dir * offset).r;
        float g = uTexture.sample(uSampler, uv).g;
        float b = uTexture.sample(uSampler, uv - dir * offset).b;
        baseColor = float4(r, g, b, 1.0);
    } else {
        baseColor = uTexture.sample(uSampler, uv);
    }

    // Sharpen
    float3 col = baseColor.rgb;
    if (u.sharpen > 0.001) {
        float3 n = uTexture.sample(uSampler, uv + float2(0.0, -u.texelSize.y)).rgb;
        float3 s = uTexture.sample(uSampler, uv + float2(0.0, u.texelSize.y)).rgb;
        float3 e = uTexture.sample(uSampler, uv + float2(u.texelSize.x, 0.0)).rgb;
        float3 w = uTexture.sample(uSampler, uv + float2(-u.texelSize.x, 0.0)).rgb;
        float3 edge = 4.0 * col - n - s - e - w;
        col = clamp(col + edge * (u.sharpen * 0.5), 0.0, 1.0);
    }

    // 2. Adjustments matching Android prototype
    float luma = getLuma(col);

    // Brightness: + b / 250.0
    col += u.brightness;

    // Contrast: around 0.5
    col = (col - 0.5) * u.contrast + 0.5;

    // Warmth: ± w / 500.0 on R and B channels
    col.r += u.warmth;
    col.b -= u.warmth;

    // Shadows / Highlights: (1-L)^2 and L^2 with / 300.0 coefficients
    float shadowCoeff = (1.0 - luma) * (1.0 - luma);
    float highlightCoeff = luma * luma;
    col += u.shadows * shadowCoeff + u.highlights * highlightCoeff;

    // Saturation: around luma
    luma = getLuma(col);
    col = mix(float3(luma), col, u.saturation);
    col = clamp(col, 0.0, 1.0);

    float3 adjustedCol = col;

    // 3. Preset Filter
    if (u.hasPreset == 1) {
        float3 pCol = adjustedCol;
        float pLuma = getLuma(pCol);

        // Preset Saturation
        pCol = mix(float3(pLuma), pCol, 1.0 + u.presetSaturation / 100.0);

        // Preset Contrast
        pCol = (pCol - 0.5) * (1.0 + u.presetContrast / 100.0) + 0.5;

        // Preset Warmth
        pCol.r += u.presetWarmth / 500.0;
        pCol.b -= u.presetWarmth / 500.0;

        // Preset Fade: lifting blacks
        pCol = pCol * (1.0 - u.presetFade) + u.presetFade;

        // Preset Tint by luminance
        float sWeight = (1.0 - pLuma) * (1.0 - pLuma);
        float hWeight = pLuma * pLuma;
        pCol += float3(u.presetShadowTint) * sWeight + float3(u.presetHighlightTint) * hWeight;

        pCol = clamp(pCol, 0.0, 1.0);

        // Lerp by intensity
        col = mix(adjustedCol, pCol, u.presetIntensity);
    }

    // 4. Effects (Film Grain, VHS)
    float totalGrain = u.grainIntensity + (u.hasPreset == 1 ? u.presetGrain * 0.01 * u.presetIntensity : 0.0);
    if (totalGrain > 0.001) {
        float noise = (randNoise(uv * 123.45) - 0.5) * totalGrain * 0.35;
        col = clamp(col + noise, 0.0, 1.0);
    }

    if (u.vhsIntensity > 0.001) {
        float scanline = sin(uv.y * 700.0) * 0.04 * u.vhsIntensity;
        col = clamp(col - scanline, 0.0, 1.0);
    }

    // 5. Border & Frame
    if (u.borderType == 1) { // Polaroid
        float topBorder = u.borderWidth * 0.6;
        float sideBorder = u.borderWidth * 0.6;
        float bottomBorder = u.borderWidth * 2.2;
        if (uv.x < sideBorder || uv.x > (1.0 - sideBorder) ||
            uv.y < topBorder || uv.y > (1.0 - bottomBorder)) {
            col = float3(0.96, 0.95, 0.93); // Kem Polaroid
        }
    } else if (u.borderType == 2) { // Film Strip
        float side = u.borderWidth * 1.0;
        if (uv.x < side || uv.x > (1.0 - side)) {
            col = float3(0.08, 0.08, 0.09);
            // Film sprocket holes
            float sp = fmod(uv.y * 14.0, 1.0);
            if (sp > 0.3 && sp < 0.7) {
                if ((uv.x > side * 0.25 && uv.x < side * 0.75) ||
                    (uv.x > (1.0 - side * 0.75) && uv.x < (1.0 - side * 0.25))) {
                    col = float3(0.92);
                }
            }
        }
    } else if (u.borderType == 3) { // Minimal White
        if (uv.x < u.borderWidth || uv.x > (1.0 - u.borderWidth) ||
            uv.y < u.borderWidth || uv.y > (1.0 - u.borderWidth)) {
            col = float3(1.0);
        }
    } else if (u.borderType == 4) { // Minimal Black
        if (uv.x < u.borderWidth || uv.x > (1.0 - u.borderWidth) ||
            uv.y < u.borderWidth || uv.y > (1.0 - u.borderWidth)) {
            col = float3(0.0);
        }
    }

    // 6. Interactive Before / After Split (Right side is raw original Before)
    if (u.splitX >= 0.0 && uv.x > u.splitX) {
        col = uTexture.sample(uSampler, uv).rgb;
    }

    return float4(col, 1.0);
}
