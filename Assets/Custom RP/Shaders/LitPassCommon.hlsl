#ifndef CUSTOM_LIT_PASS_COMMON_INCLUDED
#define CUSTOM_LIT_PASS_COMMON_INCLUDED

#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GI.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"

half3 CustomLighting(InputData inputData, SurfaceData surfaceData) {
	ShadowData shadowData = GetShadowData(inputData.positionWS, inputData.depthVS, inputData.dither);
	shadowData.shadowMask = GetShadowMask(inputData.lightmapUV);

	BRDF brdf = GetBRDF(surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, 
		surfaceData.alpha);

	float3 normal = inputData.normalWS;
	float3 position = inputData.positionWS;
	float3 viewDirection = inputData.viewDirectionWS;
	float3 interpolatedNormal = inputData.interpolatedNormalWS;
	
	half3 indirectSpecular = SampleEnvironment(viewDirection, normal, brdf.perceptualRoughness);
	half3 color = GetIndirectLighting(brdf, inputData.bakedGI, indirectSpecular,
		surfaceData.occlusion, normal, viewDirection);

	for (int i = 0; i < GetDirectionalLightCount(); ++i) {
		Light dirLight = GetDirectionalLight(i, shadowData, position, interpolatedNormal);
		color += GetLighting(brdf, dirLight, normal, viewDirection);
	}

#if defined(_LIGHTS_PER_OBJECT)
	uint otherlightCount = min(unity_LightData.y, 8);
	for (uint j = 0; j < otherlightCount; ++j) {
		int lightIndex = unity_LightIndices[j / 4][j % 4];
		Light otherLight = GetOtherLight(lightIndex, shadowData, position, interpolatedNormal);
		color += GetLighting(brdf, otherLight, normal, viewDirection);
	}
#else
	uint otherlightCount = GetOtherLightCount();
	for (uint j = 0; j < otherlightCount; ++j) {
		Light otherLight = GetOtherLight(j, shadowData, position, interpolatedNormal);
		color += GetLighting(brdf, otherLight, normal, viewDirection);
	}
#endif

	color += surfaceData.emission;
	return color;
}

#endif