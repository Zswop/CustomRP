#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection

#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
	#define SHADOWS_SHADOWMASK
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

//SAMPLER(sampler_linear_clamp);
//SAMPLER(sampler_point_clamp);

struct InputData {
	float3  positionWS;

	half3	normalWS;
	half3	tangentWS;
	half3	viewDirectionWS;
	half3	interpolatedNormalWS;
	half3	fogCoord;
	half3	bakedGI;

	float	depthVS;
	float	dither;
	float4	screenPos;
	float2	lightmapUV;
};

float Square(float x) {
	return x * x;
}

float DistanceSquared(float3 pA, float3 pB) {
	return dot(pA - pB, pA - pB);
}

void ClipLOD(float2 positionCS, float fade) {
	#if defined(LOD_FADE_CROSSFADE)
		float dither = InterleavedGradientNoise(positionCS.xy, 0);
		clip(fade + (fade < 0.0 ? dither : -dither));
	#endif
}

half3 DecodeNormal(half4 normalTS, half scale) {
	#if defined(UNITY_NO_DXT5nm)
		return UnpackNormalRGB(normalTS, scale);
	#else
		return UnpackNormalmapRGorAG(normalTS, scale);
	#endif
}

#if UNITY_REVERSED_Z
	#if SHADER_API_OPENGL || SHADER_API_GLES || SHADER_API_GLES3
		//GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
		#define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
	#else
		//D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
		//max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
		#define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z), 0)
	#endif
#elif UNITY_UV_STARTS_AT_TOP
	//D3d without reversed z => z clip range is [0, far] -> nothing to do
	#define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#else
	//Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
	#define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#endif

float4 ComputeScreenPos(float4 positionCS) {
    float4 o = positionCS * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = positionCS.zw;
    return o;
}

#endif