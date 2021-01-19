#ifndef CUSTOM_PARTICLES_UNLIT_INPUT_INCLUDED
#define CUSTOM_PARTICLES_UNLIT_INPUT_INCLUDED

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_DistortionMap); SAMPLER(sampler_DistortionMap);
TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);

CBUFFER_START(UnityPerMaterial)
	float4 _BaseMap_ST;
	float4 _BaseColor;
	float4 _FlowDirection;

	float _NearFadeDistance;
	float _NearFadeRange;

	float _SoftParticlesDistance;
	float _SoftParticlesRange;

	float4 _DistortionMap_ST;
	float4 _DistortionDirection;
	float _DistortionStrength;
	half _DistortionBlend;

	half _Distortion_Base;
	half _Distortion_Mask;
	float4 _MaskMap_ST;
CBUFFER_END

float2 TransformBaseUV(float2 baseUV) {
	return baseUV * _BaseMap_ST.xy + _BaseMap_ST.zw;
}

half4 GetBase(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	return map * _BaseColor;
}

#define TRANSFORM_TEX_FLOWUV(tex, name, flow) TRANSFORM_TEX((tex.xy + flow.xy * _Time.y), name)

half4 SampleBase(float2 uv, float2 uvOffset) {
	float2 baseUV = TRANSFORM_TEX_FLOWUV(uv, _BaseMap, _FlowDirection.xy);
	float2 distortionUV = lerp(baseUV, baseUV + uvOffset, _Distortion_Base);
	return GetBase(distortionUV);
}

half AlphaMask(float2 uv, float2 uvOffset) {
	float2 maskUV = lerp(uv, uv + uvOffset, _Distortion_Mask);
	maskUV = TRANSFORM_TEX(maskUV, _MaskMap);
	half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, maskUV).r;
	return mask;
	return 1.0;
}

float2 DistortionUVOffset(float2 uv) {
	float2 flowuv = TRANSFORM_TEX_FLOWUV(uv, _DistortionMap, _DistortionDirection.xy);
	float2 distortion = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, flowuv).xy;
	float2 uvOffset = distortion * 2.0 - 1.0; //(0,1) to (-0.5,0.5)
	uvOffset *= _DistortionStrength;
	return uvOffset;
}

float2 DistortionUVOffset_XY(float2 uv) {
	float2 uv1 = TRANSFORM_TEX_FLOWUV(uv, _DistortionMap, _DistortionDirection.xy);
	float2 uv2 = TRANSFORM_TEX_FLOWUV(uv, _DistortionMap, _DistortionDirection.zw);
	float distortionX = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, uv1).r;
	float distortionY = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, uv2).r;
	float2 uvOffset =  float2(distortionX, distortionY)  * 2.0 - 1.0; //(0,1) to (-0.5,0.5)
	uvOffset *= _DistortionStrength;
	return uvOffset;
}

#if defined(_DISTORTION)
	#define DISTORTION_UV_OFFSET(uv) DistortionUVOffset(uv)
#elif defined(_DISTORTION_XY)
	#define DISTORTION_UV_OFFSET(uv) DistortionUVOffset_XY(uv)
#else
	#define DISTORTION_UV_OFFSET(uv) 0.0
#endif

#endif