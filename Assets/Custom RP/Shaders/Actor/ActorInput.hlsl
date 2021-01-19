#ifndef CUSTOM_ACTOR_INPUT_INCLUDED
#define CUSTOM_ACTOR_INPUT_INCLUDED

#include "../Surface.hlsl"

TEXTURE2D(_BaseMap);
TEXTURE2D(_NormalMap);
TEXTURE2D(_MaskMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
	float4 _BaseMap_ST;
	half4 _BaseColor;
	half _Cutoff;
	half _NormalScale;

	half _Metallic;
	half _Occlusion;
	half _Smoothness;
	half _Fresnel;

	half4 _EmissionColor;

	half4 _RimViewColor;
	half _RimViewMask;

	half4 _RimSunColor;
	half _RimSunPower;
	half _RimSunIntensity;
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

half4 GetMODS(float4 baseUV) {
	half4 mods = half4(_Metallic, _Occlusion, 1.0, _Smoothness);
	return SampleMODSMask(baseUV.xy, _MaskMap, sampler_BaseMap, mods);
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

	half4 mods = GetMODS(uv);
	surfaceData.metallic = mods.r;
	surfaceData.smoothness = mods.a;
	surfaceData.occlusion = mods.g;
	surfaceData.fresnel = _Fresnel;

	surfaceData.emission = GetEmission(uv);
}

#endif