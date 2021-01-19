#ifndef CUSTOM_TOON_EYE_INPUT_INCLUDED
#define CUSTOM_TOON_EYE_INPUT_INCLUDED

#include "../Surface.hlsl"

TEXTURE2D(_BaseMap);
TEXTURE2D(_NormalMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
	float4 _BaseMap_ST;
	half4 _BaseColor;
	half _Cutoff;
	half _NormalScale;

	half _TSFlat;
	half _TSRollOff;
	half _TSScatterWidth;
	half4 _TSScatterColor;

	half _SpecularSegment;
	half _SpecularSegmentWidth;
	half _EyeShininess;
	half4 _CelEyeSpecColor;

	half _MatcapIntensity;
	half _MatcapShift;

	half4 _EmissionColor;
CBUFFER_END

float4 TransformBaseUV(float2 baseUV) {
	float2 uv = baseUV.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
	return float4(uv, 0.0, 0.0);
}

half4 GetBase(float4 baseUV) {
	half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV.xy);
	return map * _BaseColor;
}

half GetCutoff(float4 baseUV) {
	return _Cutoff;
}

////////////////////////////////////////////////

half3 GetNormalTS(float4 baseUV) {
	return SampleNormal(baseUV.xy, _NormalMap, sampler_BaseMap, _NormalScale);
}

half3 GetEmission(float4 baseUV) {
	return SampleEmission(baseUV.xy, _EmissionColor.rgb, _EmissionMap, sampler_BaseMap);
}

inline void InitializeSurfaceData(float4 uv, out SurfaceData surfaceData) {
	ZERO_INITIALIZE(SurfaceData, surfaceData)

	half4 base = GetBase(uv);
	surfaceData.albedo = base.rgb;
	surfaceData.alpha = Alpha(base.a, GetCutoff(uv));
	surfaceData.normalTS = GetNormalTS(uv);

	surfaceData.metallic = 0.0;
	surfaceData.smoothness = 0.0;
	surfaceData.occlusion = 1.0;
	surfaceData.fresnel = 1.0;

	surfaceData.emission = GetEmission(uv);
}

#endif