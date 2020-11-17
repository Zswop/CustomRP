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
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

float2 TransformBaseUV(float2 baseUV) {
	float4 baseST = INPUT_PROP(_BaseMap_ST);
	return baseUV * baseST.xy + baseST.zw;
}

float4 GetBase(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = INPUT_PROP(_BaseColor);
	return map * color;
}

float GetCutoff(float2 baseUV) {
	return INPUT_PROP(_Cutoff);
}

///////////////////////////////////////////////////////////////

float3 GetNormalTS(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_BaseMap, baseUV);
	float scale = INPUT_PROP(_NormalScale);
	float3 normal = DecodeNormal(map, scale);
	return normal;
}

float4 GetMask(float2 baseUV) {
	#if defined(_MASK_MAP)
		return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, baseUV);
	#endif
	return 1.0;
}

float GetMetallic(float2 baseUV) {
	float metallic = INPUT_PROP(_Metallic);
	metallic *= GetMask(baseUV).r;
	return metallic;
}

float GetOcclusion(float2 baseUV) {
	float strength = INPUT_PROP(_Occlusion);
	float occlusion = GetMask(baseUV).g;
	return lerp(1, occlusion, strength);
}

float GetSmoothness(float2 baseUV) {
	float smoothness = INPUT_PROP(_Smoothness);
	smoothness *= GetMask(baseUV).a;
	return smoothness;
}

float3 GetEmission(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, baseUV);
	float4 color = INPUT_PROP(_EmissionColor);
	return map.rgb * color.rgb;
}

float GetFresnel(float2 baseUV) {
	return INPUT_PROP(_Fresnel);
}

inline void InitializeSurfaceData(float2 uv, out SurfaceData surfaceData) {
	ZERO_INITIALIZE(SurfaceData, surfaceData)

	float4 base = GetBase(uv);
	surfaceData.albedo = base.rgb;
	surfaceData.alpha = base.a;
	surfaceData.cutoff = GetCutoff(uv);

	surfaceData.normalTS = GetNormalTS(uv);

	surfaceData.metallic = GetMetallic(uv);
	surfaceData.smoothness = GetSmoothness(uv);
	surfaceData.occlusion = GetOcclusion(uv);
	surfaceData.fresnel = GetFresnel(uv);

	surfaceData.emission = GetEmission(uv);
}

#endif