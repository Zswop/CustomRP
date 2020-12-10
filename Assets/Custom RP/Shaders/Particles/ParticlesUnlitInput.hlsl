#ifndef CUSTOM_PARTICLES_UNLIT_INPUT_INCLUDED
#define CUSTOM_PARTICLES_UNLIT_INPUT_INCLUDED

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_DistortionMap); SAMPLER(sampler_DistortionMap);

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
	half _DistortionBase;
	half _DistortionBlend;
CBUFFER_END

float2 TransformBaseUV(float2 baseUV) {
	return baseUV * _BaseMap_ST.xy + _BaseMap_ST.zw;
}

half4 GetBase(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	return map * _BaseColor;
}

half GetDistortionBlend() {
	return _DistortionBlend;
}

float2 DistortionUVOffset(float2 uv) {
	float2 uvOffset = 0.0;
#if defined(_DISTORTION)
	float2 uv1 = TRANSFORM_TEX_FLOWUV(uv, _DistortionMap, _DistortionDirection.xy);
	float2 uv2 = TRANSFORM_TEX_FLOWUV(uv, _DistortionMap, _DistortionDirection.zw);
	float distortionX = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, uv1).r;
	float distortionY = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, uv2).r;
	uvOffset = float2(distortionX, distortionY) - 0.5; //(0,1) to (-0.5,0.5)
	uvOffset *= _DistortionStrength;
#endif
	return uvOffset;
}

half4 DistortionBase(float2 uv, float2 uvOffset) {
	float2 baseUV = TRANSFORM_TEX_FLOWUV(uv, _BaseMap, _FlowDirection.xy);
	float2 distortionUV = lerp(baseUV, baseUV + uvOffset, _DistortionBase);
	return GetBase(distortionUV);
}

#endif