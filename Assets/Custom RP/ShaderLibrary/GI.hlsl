#ifndef CUSTOM_GI_INCLUDED
#define CUSTOM_GI_INCLUDED

#if defined(LIGHTMAP_ON)
	#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
	#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
	#define TRANSFER_GI_DATA(input, output) \
		output.lightMapUV = input.lightMapUV * \
			unity_LightmapST.xy + unity_LightmapST.zw;
	#define GI_FRAGMENT_DATA(input) input.lightMapUV
	#define SAMPLE_GI(lmName, normalWSName) SampleLightMap(lmName)
#else
	#define GI_ATTRIBUTE_DATA
	#define GI_VARYINGS_DATA
	#define TRANSFER_GI_DATA(input, output)
	#define GI_FRAGMENT_DATA(input) 0.0
	#define SAMPLE_GI(lmName, normalWSName) SampleLightProbe(normalWSName)
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);

float3 SampleLightMap(float2 lightMapUV) {
	return SampleSingleLightmap(
			TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightMapUV,
			float4(1.0, 1.0, 0.0, 0.0),
			#if defined(UNITY_LIGHTMAP_FULL_HDR)
				false,
			#else
				true,
			#endif
			float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0)
	);
}

float3 SampleLightProbe(float3 normalWS) {
	float4 coefficients[7];
	coefficients[0] = unity_SHAr;
	coefficients[1] = unity_SHAg;
	coefficients[2] = unity_SHAb;
	coefficients[3] = unity_SHBr;
	coefficients[4] = unity_SHBg;
	coefficients[5] = unity_SHBb;
	coefficients[6] = unity_SHC;
	return max(0.0, SampleSH9(coefficients, normalWS));
}

float3 SampleEnvironment(float3 viewDirectionWS, float3 normalWS, float perceptualRoughness) {
	float3 uvw = reflect(-viewDirectionWS, normalWS);
	float mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
	float4 environment = SAMPLE_TEXTURECUBE_LOD(
		unity_SpecCube0, samplerunity_SpecCube0, uvw, mip);
	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

float3 SampleGI(float2 lightmapUV, float3 normalWS) {
	return SAMPLE_GI(lightmapUV, normalWS);
}

float4 SampleBakedShadows(float2 lightMapUV) {
	#if defined(LIGHTMAP_ON)
		return SAMPLE_TEXTURE2D(
			unity_ShadowMask, samplerunity_ShadowMask, lightMapUV);
	#else
		return unity_ProbesOcclusion;
	#endif
}

ShadowMask GetShadowMask(float2 lightMapUV) {
	ShadowMask shadowMask;
	shadowMask.always = false;
	shadowMask.distance = false;
	shadowMask.shadows = 1.0;

	#if defined(_SHADOW_MASK_ALWAYS)
		shadowMask.always = true;
		shadowMask.shadows = SampleBakedShadows(lightMapUV);
	#elif defined(_SHADOW_MASK_DISTANCE)
		shadowMask.distance = true;
		shadowMask.shadows = SampleBakedShadows(lightMapUV);
	#endif
	return shadowMask;
}

#endif