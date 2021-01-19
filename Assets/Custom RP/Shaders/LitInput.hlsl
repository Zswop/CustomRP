#ifndef CUSTOM_LIT_INPUT_INCLUDED
#define CUSTOM_LIT_INPUT_INCLUDED

#include "Surface.hlsl"

TEXTURE2D(_BaseMap);
TEXTURE2D(_NormalMap);
TEXTURE2D(_MaskMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_BaseMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(half, _NormalScale)
	UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(half, _Occlusion)
	UNITY_DEFINE_INSTANCED_PROP(half, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(half, _Fresnel)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

float4 TransformBaseUV(float2 baseUV) {
	float4 baseST = INPUT_PROP(_BaseMap_ST);
	float2 uv = baseUV * baseST.xy + baseST.zw;
	return float4(uv, 0.0, 0.0);
}

half4 GetBase(float4 baseUV) {
	half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV.xy);
	half4 color = INPUT_PROP(_BaseColor);
	return map * color;
}

half GetCutoff(float4 baseUV) {
	return INPUT_PROP(_Cutoff);
}

///////////////////////////////////////////////////////////////

half3 GetNormalTS(float4 baseUV) {
	half scale = INPUT_PROP(_NormalScale);
	return SampleNormal(baseUV.xy, _NormalMap, sampler_BaseMap, scale);
}

half4 GetMODS(float4 baseUV) {
	half4 mods = half4(INPUT_PROP(_Metallic), INPUT_PROP(_Occlusion), 1.0, INPUT_PROP(_Smoothness));
	return SampleMODSMask(baseUV.xy, _MaskMap, sampler_BaseMap, mods);
}

half3 GetEmission(float4 baseUV) {
	half4 color = INPUT_PROP(_EmissionColor);
	return SampleEmission(baseUV.xy, color.rgb, _EmissionMap, sampler_BaseMap);
}

half GetFresnel(float4 baseUV) {
	return INPUT_PROP(_Fresnel);
}

inline void InitializeSurfaceData(float4 uv, out SurfaceData surfaceData) {
	ZERO_INITIALIZE(SurfaceData, surfaceData)

	half4 base = GetBase(uv);
	surfaceData.albedo = base.rgb;
	surfaceData.alpha = Alpha(base.a, GetCutoff(uv));
	surfaceData.normalTS = GetNormalTS(uv);

	half4 mods = GetMODS(uv);
	surfaceData.metallic = mods.r;
	surfaceData.occlusion = mods.g;
	surfaceData.smoothness = mods.a;
	surfaceData.fresnel = GetFresnel(uv);

	surfaceData.emission = GetEmission(uv);
}

#endif