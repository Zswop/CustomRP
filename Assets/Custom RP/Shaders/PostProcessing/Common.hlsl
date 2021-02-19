#ifndef CUSTOM_POSTPROCESSING_COMMON_INCLUDED
#define CUSTOM_POSTPROCESSING_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

struct Varyings {
	float4 positionCS : SV_POSITION;
	float2 fxUV : VAR_FX_UV;
};

Varyings DefaultPassVertex(uint vertexID : SV_VertexID) {
	Varyings output;

	float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
	output.positionCS = float4(uv * 2.0 - 1.0, 0.0, 1.0);
	output.fxUV = uv;
	if (_ProjectionParams.x < 0.0) {
		output.fxUV.y = 1.0 - output.fxUV.y;
	}
	return output;
}

SAMPLER(sampler_linear_clamp);
SAMPLER(sampler_PointClamp);

half3 ApplyBloomThreshold(half3 color, float4 bloomThreshold) 
{
	//TODO: User controlled clamp to limit crazy high broken spec
	float brightness = Max3(color.r, color.g, color.b);
	float soft = brightness + bloomThreshold.y;
	soft = clamp(soft, 0.0, bloomThreshold.z);
	soft = soft * soft * bloomThreshold.w;
	float contribution = max(soft, brightness - bloomThreshold.x);
	contribution /= max(brightness, 0.00001);
	return color * contribution;
}

half4 BlurHorizontal(float2 uv, TEXTURE2D_PARAM(sourceTex, sampler_sourceTex), float texelSize)
{
	// 9-tap gaussian blur on the downsampled source
	half3 c0 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv - float2(texelSize * 4.0, 0.0)).rgb;
	half3 c1 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv - float2(texelSize * 3.0, 0.0)).rgb;
	half3 c2 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv - float2(texelSize * 2.0, 0.0)).rgb;
	half3 c3 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv - float2(texelSize * 1.0, 0.0)).rgb;
	half3 c4 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv).rgb;
	half3 c5 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + float2(texelSize * 1.0, 0.0)).rgb;
	half3 c6 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + float2(texelSize * 2.0, 0.0)).rgb;
	half3 c7 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + float2(texelSize * 3.0, 0.0)).rgb;
	half3 c8 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + float2(texelSize * 4.0, 0.0)).rgb;

	half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 + c3 * 0.19459459
		+ c4 * 0.22702703
		+ c5 * 0.19459459 + c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;

	return half4(color, 1.0);
}

half4 BlurVertical(float2 uv, TEXTURE2D_PARAM(sourceTex, sampler_sourceTex), float texelSize)
{
	// Optimized bilinear 5-tap gaussian on the same-sized source (9-tap equivalent)
	half3 c0 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv - float2(0.0, texelSize * 3.23076923)).rgb;
	half3 c1 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv - float2(0.0, texelSize * 1.38461538)).rgb;
	half3 c2 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv).rgb;
	half3 c3 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + float2(0.0, texelSize * 1.38461538)).rgb;
	half3 c4 = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + float2(0.0, texelSize * 3.23076923)).rgb;

	half3 color = c0 * 0.07027027 + c1 * 0.31621622
		+ c2 * 0.22702703
		+ c3 * 0.31621622 + c4 * 0.07027027;

	return half4(color, 1.0);
}

half4 SampleBox4(float2 uv, TEXTURE2D_PARAM(sourceTex, sampler_sourceTex), float2 texelSize, float scale)
{
	float4 d = texelSize.xyxy * float2(-scale, scale).xxyy;
	half4 s = SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + d.xy) +
		SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + d.zy) +
		SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + d.xw) +
		SAMPLE_TEXTURE2D(sourceTex, sampler_sourceTex, uv + d.zw);
	return s * 0.25;
}

half3 ApplyColorGradingLUT (float3 input, TEXTURE2D_PARAM(lutTex, lutSampler), float3 lutParams) {
	float3 inputLutSpace = saturate(LinearToLogC(input)); // LUT space is in LogC
	return ApplyLut2D(TEXTURE2D_ARGS(lutTex, lutSampler), inputLutSpace, lutParams);
}

half3 ApplyVignette(half3 input, half3 vignetteColor, float2 uv, float2 center, 
	float intensity, float roundness, float smoothness) {
    float2 dist = abs(uv - center) * intensity;
    dist.x *= roundness;

    float vfactor = pow(saturate(1.0 - dot(dist, dist)), smoothness);
    return input * lerp(vignetteColor, (1.0).xxx, vfactor);
}

#endif