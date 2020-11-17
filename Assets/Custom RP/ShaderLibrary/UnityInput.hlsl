#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED

CBUFFER_START(UnityPerDraw)
	float4x4 unity_ObjectToWorld;
	float4x4 unity_WorldToObject;
	float4 unity_LODFade;
	real4 unity_WorldTransformParams;

	real4 unity_LightData;
	real4 unity_LightIndices[2];

	float4 unity_ProbesOcclusion;
	float4 unity_SpecCube0_HDR;

	float4 unity_LightmapST;
	float4 unity_DynamicLightmapST;

	float4 unity_SHAr;
	float4 unity_SHAg;
	float4 unity_SHAb;
	float4 unity_SHBr;
	float4 unity_SHBg;
	float4 unity_SHBb;
	float4 unity_SHC;
CBUFFER_END

float4x4 unity_MatrixV;
float4x4 unity_MatrixVP;
float4x4 glstate_matrix_projection;

float4 _Time;  // (t/20, t, t*2, t*3)

float3 _WorldSpaceCameraPos;

// x = 1 or -1 (-1 if projection is flipped)
// y = near plane
// z = far plane
// w = 1/far plane
float4 _ProjectionParams;

// Values used to linearize the Z buffer (http://www.humus.name/temp/Linearize%20depth.txt)
// x = 1-far/near
// y = far/near
// z = x/far
// w = y/far
// or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1)
// x = -1+far/near
// y = 1
// z = x/far
// w = 1/far
float4 _ZBufferParams;

#endif