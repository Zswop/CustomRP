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
	half4 _BaseColor;
	half _Metallic;
	half _Smoothness;

	half3 _WaterFogColor;
	half _WaterFogDensity;
	half _RefractionStrength;

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

float4 TransformBaseUV(float2 baseUV) {
	float2 uv = baseUV.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
	return float4(uv, 0.0, 0.0);
}

half4 GetBase(float4 baseUV) {
	half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV.xy);
	return map * _BaseColor;
}

half GetCutoff(float4 baseUV) {
	return 0.0;
}

////////////////////////////////////////////////

half3 GetDerivativeHeight (float2 uv) {
	half3 dh = SAMPLE_TEXTURE2D(_DerivHeightMap, sampler_DerivHeightMap, uv).agb;
	dh.xy = dh.xy * 2 - 1;
	return dh;
}

inline void InitializeWaterWaveData(float3 p, out WaveData waveData) {
	waveData = GetGerstnerWave(_WaveA, _WaveB, _WaveC, p);
}

inline half4 GetFlowBase(float2 uv, out half3 normal){
	half4 flow = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, uv);
	flow.xy = flow.xy * 2 - 1.0;
	flow.xyz *= _FlowStrength;

	float time = _Time.y * _Speed + flow.w;
	float2 jump = float2(_UJump, _VJump);
	float3 uvwA = FlowUVW(uv, flow.xy, jump, _FlowOffset, _Tiling, time, false);
	float3 uvwB = FlowUVW(uv, flow.xy, jump, _FlowOffset, _Tiling, time, true);

	half4 baseA = GetBase(float4(uvwA.xy, 0.0, 0.0)) * uvwA.z;
	half4 baseB = GetBase(float4(uvwB.xy, 0.0, 0.0)) * uvwB.z;
	half4 base = baseA + baseB;
		
	half finalHeightScale = flow.z * _HeightScaleModulated + _HeightScale;
	half3 dhA = GetDerivativeHeight(uvwA.xy) * uvwA.z * finalHeightScale;
	half3 dhB = GetDerivativeHeight(uvwB.xy) * uvwB.z * finalHeightScale;
	normal = normalize(half3(-(dhA.xy + dhB.xy), 1));
	//base.rgb = pow(dhA.z + dhB.z, 2);
	return base;
}

inline void InitializeWaterSurfaceData(float4 uv, out SurfaceData surfaceData) {
	ZERO_INITIALIZE(SurfaceData, surfaceData)

	half3 normal;
	half4 base = GetFlowBase(uv.xy, normal);
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