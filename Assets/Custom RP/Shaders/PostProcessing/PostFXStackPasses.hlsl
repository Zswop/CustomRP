#ifndef CUSTOM_POST_FX_PASSES_INCLUDED
#define CUSTOM_POST_FX_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

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

#define _PostFXSource _BlitTex
#define _PostFXSource_TexelSize _BlitTex_TexelSize;

TEXTURE2D(_PostFXSource);
TEXTURE2D(_PostFXSourceLowMip);
SAMPLER(sampler_linear_clamp);

float4 _PostFXSource_TexelSize;
float4 _PostFXSourceLowMip_TexelSize;
float4 _BloomThreshold;
float _BloomIntensity;

float4 GetSourceTexelSize() {
	return _PostFXSource_TexelSize;
}

half4 GetSource(float2 fxUV) {
	return SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, fxUV);
}

half4 BlurPassFragment(Varyings input) : SV_TARGET {
	float2 uv = input.fxUV;
	float4 texelSize =  GetSourceTexelSize();
	float4 d = texelSize.xyxy * float4(-0.5, -0.5, 0.5, 0.5);

	half4 s;
    s =  (GetSource(uv + d.xy));
    s += (GetSource(uv + d.zy));
    s += (GetSource(uv + d.xw));
    s += (GetSource(uv + d.zw));
    return s * 0.25h;
}

half4 GetSourceLowMip(float2 fxUV) {
	return SAMPLE_TEXTURE2D(_PostFXSourceLowMip, sampler_linear_clamp, fxUV);
}

float4 GetSourceLowMip2DBicubic(float2 fxUV) {
	return SampleTexture2DBicubic(TEXTURE2D_ARGS(_PostFXSourceLowMip, sampler_linear_clamp),
		fxUV, _PostFXSourceLowMip_TexelSize.zwxy, 1.0, 0.0);
}

half3 ApplyBloomThreshold(half3 color) {
	float brightness = Max3(color.r, color.g, color.b);
	float soft = brightness + _BloomThreshold.y;
	soft = clamp(soft, 0.0, _BloomThreshold.z);
	soft = soft * soft * _BloomThreshold.w;
	float contribution = max(soft, brightness - _BloomThreshold.x);
	contribution /= max(brightness, 0.00001);
	return color * contribution;
}

half4 BloomPrefilterPassFragment(Varyings input) : SV_TARGET {
	half4 color = GetSource(input.fxUV);
	return half4(ApplyBloomThreshold(color.rgb), 1.0);
}

half4 BloomHorizontalPassFragment(Varyings input) : SV_TARGET {
	float texelSize = GetSourceTexelSize().x * 2.0;
	float2 uv = input.fxUV;

	// 9-tap gaussian blur on the downsampled source
	half3 c0 = GetSource(uv - float2(texelSize * 4.0, 0.0)).rgb;
	half3 c1 = GetSource(uv - float2(texelSize * 3.0, 0.0)).rgb;
	half3 c2 = GetSource(uv - float2(texelSize * 2.0, 0.0)).rgb;
	half3 c3 = GetSource(uv - float2(texelSize * 1.0, 0.0)).rgb;
	half3 c4 = GetSource(uv).rgb;
	half3 c5 = GetSource(uv + float2(texelSize * 1.0, 0.0)).rgb;
	half3 c6 = GetSource(uv + float2(texelSize * 2.0, 0.0)).rgb;
	half3 c7 = GetSource(uv + float2(texelSize * 3.0, 0.0)).rgb;
	half3 c8 = GetSource(uv + float2(texelSize * 4.0, 0.0)).rgb;

	half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 + c3 * 0.19459459
		+ c4 * 0.22702703
		+ c5 * 0.19459459 + c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;

	return half4(color, 1.0);
}

half4 BloomVerticalPassFragment(Varyings input) : SV_TARGET {
	float texelSize = GetSourceTexelSize().y;
	float2 uv = input.fxUV;

	// Optimized bilinear 5-tap gaussian on the same-sized source (9-tap equivalent)
	half3 c0 = GetSource(uv - float2(0.0, texelSize * 3.23076923)).rgb;
	half3 c1 = GetSource(uv - float2(0.0, texelSize * 1.38461538)).rgb;
	half3 c2 = GetSource(uv).rgb;
	half3 c3 = GetSource(uv + float2(0.0, texelSize * 1.38461538)).rgb;
	half3 c4 = GetSource(uv + float2(0.0, texelSize * 3.23076923)).rgb;

	half3 color = c0 * 0.07027027 + c1 * 0.31621622
		+ c2 * 0.22702703
		+ c3 * 0.31621622 + c4 * 0.07027027;
	return half4(color, 1.0);
}

half4 BloomAddPassFragment(Varyings input) : SV_TARGET {
	half3 highRes = GetSource(input.fxUV).rgb;
	half3 lowRes = GetSourceLowMip2DBicubic(input.fxUV).rgb;
	return half4(lowRes * _BloomIntensity + highRes, 1.0);
}

half4 BloomScatterPassFragment(Varyings input) : SV_TARGET {
	half3 highRes = GetSource(input.fxUV).rgb;
	half3 lowRes = GetSourceLowMip2DBicubic(input.fxUV).rgb;
	return half4(lerp(highRes, lowRes, _BloomIntensity), 1.0);
}

half4 BloomScatterFinalPassFragment(Varyings input) : SV_TARGET {
	half3 highRes = GetSource(input.fxUV).rgb;
	half3 lowRes = GetSourceLowMip2DBicubic(input.fxUV).rgb;
	lowRes += highRes - ApplyBloomThreshold(highRes);
	return half4(lerp(highRes, lowRes, _BloomIntensity), 1.0);
}

half4 CopyPassFragment(Varyings input) : SV_TARGET {
	return GetSource(input.fxUV);
}

//Color Grading

#include "ColorGrading.hlsl"

float4 _ColorGradingLUTParameters;

float3 GetColorGradedLUT (float2 uv, bool useACES = false) {
	float3 color = GetLutStripValue(uv, _ColorGradingLUTParameters);
	return ColorGrade(color, useACES);
}

half4 ColorGradingPassFragment(Varyings input) : SV_TARGET {
	half3 color = GetColorGradedLUT(input.fxUV);
	return half4(color, 1.0);
}

half4 ColorGradedACESPassFragment(Varyings input) : SV_TARGET {
	half3 color = GetColorGradedLUT(input.fxUV, true);
	color = AcesTonemap(unity_to_ACES(color));
	return half4(color, 1.0);
}

half4 ColorGradedNeutralPassFragment(Varyings input) : SV_TARGET {
	half3 color = GetColorGradedLUT(input.fxUV);
	color = NeutralTonemap(color);
	return half4(color, 1.0);
}

TEXTURE2D(_ColorGradingLUT);

float3 ApplyColorGradingLUT (float3 color) {
	return ApplyLut2D(TEXTURE2D_ARGS(_ColorGradingLUT, sampler_linear_clamp),
		saturate(color), _ColorGradingLUTParameters.xyz);
}

half4 ColorGradingFinalPassFragment(Varyings input) : SV_TARGET {
	half4 color = GetSource(input.fxUV);
	color.rgb = ApplyColorGradingLUT(color.rgb);
	return color;
}

//FXAA

half4 FXAALuminancePassFragment(Varyings input) : SV_TARGET {
	half4 color = GetSource(input.fxUV);
	color.a = Luminance(color.rgb);
	return color;
}

half GetSourceLuminance(float2 fxUV) {
	return SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, fxUV).a;
}

#define FXAA_SAMPLE_LUMINANCE(uv) GetSourceLuminance(uv)
#define FXAA_SAMPLE_SOURCE(uv) GetSource(uv)
#define FXAA_SOURCE_SIZE GetSourceTexelSize()

#include "FXAA.hlsl"

half4 FXAAPassFragment(Varyings input) : SV_TARGET {
	half4 color = ApplyFXAA(input.fxUV);
	return color;
}

#endif