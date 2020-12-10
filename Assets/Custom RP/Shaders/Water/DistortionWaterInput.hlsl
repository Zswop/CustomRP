#ifndef CUSTOM_DISTORTION_WATER_INPUT_INCLUDED
#define CUSTOM_DISTORTION_WATER_INPUT_INCLUDED

#include "../Surface.hlsl"

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_FlowMap); SAMPLER(sampler_FlowMap);
TEXTURE2D(_DerivHeightMap); SAMPLER(sampler_DerivHeightMap);
TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

CBUFFER_START(UnityPerMaterial)
	float4 _BaseMap_ST;
	float4 _BaseColor;
	float _Metallic;
	float _Smoothness;

	float3 _WaterFogColor;
	float _WaterFogDensity;
	float _RefractionStrength;

	float _UJump;
	float _VJump;
	float _Tiling;
	float _Speed;
	float _FlowStrength;
	float _FlowOffset;
	float _HeightScale;
	float _HeightScaleModulated;

	float4 _WaveA;
	float4 _WaveB;
	float4 _WaveC;
CBUFFER_END

float2 TransformBaseUV(float2 baseUV) {
	return baseUV * _BaseMap_ST.xy + _BaseMap_ST.zw;
}

float4 GetBase(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	return map * _BaseColor;
}

float GetCutoff(float2 baseUV) {
	return 0.0;
}

////////////////////////////////////////////////

float3 GetDerivativeHeight (float2 uv) {
	float3 dh = SAMPLE_TEXTURE2D(_DerivHeightMap, sampler_DerivHeightMap, uv).agb;
	dh.xy = dh.xy * 2 - 1;
	return dh;
}

inline void InitializeWaterWaveData(float3 p, out WaveData waveData) {
	waveData = GetGerstnerWave(_WaveA, _WaveB, _WaveC, p);
}

inline float4 GetFlowBase(float2 uv, out float3 normal){
	float4 flow = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, uv);
	flow.xy = flow.xy * 2 - 1.0;
	flow.xyz *= _FlowStrength;

	float time = _Time.y * _Speed + flow.w;
	float2 jump = float2(_UJump, _VJump);

	float3 uvwA = FlowUVW(uv, flow.xy, jump, _FlowOffset, _Tiling, time, false);
	float3 uvwB = FlowUVW(uv, flow.xy, jump, _FlowOffset, _Tiling, time, true);

	float4 baseA = GetBase(uvwA.xy) * uvwA.z;
	float4 baseB = GetBase(uvwB.xy) * uvwB.z;
	float4 base = baseA + baseB;
		
	float finalHeightScale = flow.z * _HeightScaleModulated + _HeightScale;
	float3 dhA = GetDerivativeHeight(uvwA.xy) * uvwA.z * finalHeightScale;
	float3 dhB = GetDerivativeHeight(uvwB.xy) * uvwB.z * finalHeightScale;
	normal = normalize(float3(-(dhA.xy + dhB.xy), 1));
	return base;
}

inline void InitializeWaterSurfaceData(float2 uv, out SurfaceData surfaceData) {
	ZERO_INITIALIZE(SurfaceData, surfaceData)

	float3 normal;
	float4 base = GetFlowBase(uv, normal);
	//surfaceData.albedo = pow(dhA.z + dhB.z, 2);
	surfaceData.albedo = base.rgb;
	surfaceData.alpha = base.a;
	surfaceData.normalTS = normal;

	surfaceData.cutoff = 0.0;
	surfaceData.metallic = _Metallic;
	surfaceData.smoothness = _Smoothness;
	surfaceData.occlusion = 1.0;
	surfaceData.fresnel = 1.0;
	surfaceData.emission = 0.0;
}

#endif