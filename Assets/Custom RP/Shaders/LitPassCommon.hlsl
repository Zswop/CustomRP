#ifndef CUSTOM_LIT_PASS_COMMON_INCLUDED
#define CUSTOM_LIT_PASS_COMMON_INCLUDED

#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GI.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"
#include "../ShaderLibrary/Fog.hlsl"

#include "./Lighting/IndirectLighting.hlsl"
#include "./Lighting/RealTimeLighting.hlsl"
#include "./Lighting/EmissionLighting.hlsl"

half3 CustomLighting(InputData inputData, SurfaceData surfaceData) {
	ShadowData shadowData = GetShadowData(inputData.positionWS, inputData.depthVS, inputData.dither);
	shadowData.shadowMask = GetShadowMask(inputData.lightmapUV);
	
	float3 position = inputData.positionWS;
	float3 interpolatedNormal = inputData.interpolatedNormalWS;
	BRDF brdf = GetBRDF(surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness,
		surfaceData.alpha);
	
	half3 color = IndirectLighting(inputData, surfaceData, brdf);	

	Light mainDirLight = GetMainDirectionLight(shadowData, position, interpolatedNormal);
	color += RealTimeLighting(inputData, surfaceData, brdf, mainDirLight);
	
	for (int i = 1; i < GetDirectionalLightCount(); ++i) {
		Light dirLight = GetDirectionalLight(i, shadowData, position, interpolatedNormal);
		color += RealTimeLighting(inputData, surfaceData, brdf, dirLight);
	}

#if defined(_LIGHTS_PER_OBJECT)
	uint otherlightCount = min(unity_LightData.y, 8);
	for (uint j = 0; j < otherlightCount; ++j) {
		int lightIndex = unity_LightIndices[j / 4][j % 4];
		Light otherLight = GetOtherLight(lightIndex, shadowData, position, interpolatedNormal);
		color += RealTimeLighting(inputData, surfaceData, brdf, otherLight);
	}
#else
	uint otherlightCount = GetOtherLightCount();
	for (uint j = 0; j < otherlightCount; ++j) {
		Light otherLight = GetOtherLight(j, shadowData, position, interpolatedNormal);
		color += RealTimeLighting(inputData, surfaceData, brdf, otherLight);
	}
#endif

	color += EmissionLighting(inputData, surfaceData, brdf, mainDirLight);
	return color;
}

half4 OutputColor(half3 color, InputData inputData, SurfaceData surfaceData) {
	color = ApplyFog(color, inputData.fogCoord);
	return half4(color, surfaceData.alpha);
}

#endif