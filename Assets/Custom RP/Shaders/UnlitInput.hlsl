#ifndef CUSTOM_LIT_INPUT_INCLUDED
#define CUSTOM_LIT_INPUT_INCLUDED

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float4 TransformBaseUV(float2 baseUV) {
	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	float2 uv = baseUV.xy * baseST.xy + baseST.zw;
	return float4(uv, 0.0, 0.0);
}

half4 GetBase(float4 baseUV) {
	half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV.xy);
	half4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	return map * color;
}

half GetCutoff(float4 baseUV) {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

#endif