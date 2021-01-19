#ifndef CUSTOM_DIRECTIONAL_WATER_INPUT_INCLUDED
#define CUSTOM_DIRECTIONAL_WATER_INPUT_INCLUDED

#include "../Surface.hlsl"

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_FlowMap); SAMPLER(sampler_FlowMap);
TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

CBUFFER_START(UnityPerMaterial)
	float4 _BaseMap_ST;
	half4 _BaseColor;
	half _Metallic;
	half _Smoothness;

	half3 _WaterFogColor;
	half _WaterFogDensity;
	half _RefractionStrength;

	float _Tiling;
	float _TilingModulated;
	float _GridResolution;
	float _Speed;
	float _FlowStrength;
	float _HeightScale;
	float _HeightScaleModulated;

	float4 _WaveA;
	float4 _WaveB;
	float4 _WaveC;
CBUFFER_END

float4 TransformBaseUV(float2 baseUV) {
	float2 uv = baseUV.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
	return float4(uv, 0.0, 0.0);
}

half4 GetBase(float4 baseUV) {
	return _BaseColor;
}

float GetCutoff(float4 baseUV) {
	return 0.0;
}

////////////////////////////////////////////////

float3 GetDerivativeHeight(float2 uv) {
	float3 dh = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv).agb;
	dh.xy = dh.xy * 2 - 1;
	return dh;
}

inline void InitializeWaterWaveData(float3 p, out WaveData waveData) {
	waveData = GetGerstnerWave(_WaveA, _WaveB, _WaveC, p);
}

float3 FlowCell(float2 uv, float2 offset, float time) {
	offset *= 0.5;  // Overlapping Cells
	float2 shift = 0.5 - offset;  //Sampling At Cell Centers
	float2 uvTiled = (floor(uv * _GridResolution + offset) + shift) / _GridResolution;
	float4 flow = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, uvTiled);
	flow.xy = flow.xy * 2 - 1.0;
	
	float2x2 derivRotation;
	float flowSpeed = flow.z * _FlowStrength;
	float tiling = flowSpeed * _TilingModulated + _Tiling;
	float2 uvFlow = DirectionalFlowUV(uv + offset, flow.xy, flowSpeed, tiling, time, derivRotation);

	float3 dh = GetDerivativeHeight(uvFlow);
	dh.xy = mul(derivRotation, dh.xy);
	dh *= flowSpeed * _HeightScaleModulated + _HeightScale;
	return dh;
}

float3 FlowGrid (float2 uv, float time) {
	float3 dhA = FlowCell(uv, float2(0, 0), time);
	float3 dhB = FlowCell(uv, float2(1, 0), time);
	float3 dhC = FlowCell(uv, float2(0, 1), time);
	float3 dhD = FlowCell(uv, float2(1, 1), time);

	float2 t = abs(2 * frac(uv * _GridResolution) - 1);
	float wA = (1.0 - t.x) * (1.0 - t.y);
	float wB = t.x * (1.0 - t.y);
	float wC = (1.0 - t.x) * t.y;
	float wD = t.x * t.y;
	float3 dh = dhA * wA + dhB * wB + dhC * wC + dhD * wD;
	return dh;
}

inline void InitializeWaterSurfaceData(float4 uv, out SurfaceData surfaceData) {
	ZERO_INITIALIZE(SurfaceData, surfaceData)

	float time = _Time.y * _Speed;
	float3 dh = FlowGrid(uv.xy, time);
	float3 normal = normalize(float3(-(dh.xy), 1));	

	half4 base = dh.z * dh.z * _BaseColor;
	surfaceData.albedo = base.rgb;
	surfaceData.alpha = base.a;
	surfaceData.normalTS = normal;

	surfaceData.metallic = _Metallic;
	surfaceData.smoothness = _Smoothness;
	surfaceData.occlusion = 1.0;
	surfaceData.fresnel = 1.0;
	surfaceData.emission = 0.0;
}

#endif