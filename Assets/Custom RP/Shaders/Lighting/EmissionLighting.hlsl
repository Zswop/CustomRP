#ifndef CUSTOM_EMISSION_LIGHTING_INCLUDED
#define CUSTOM_EMISSION_LIGHTING_INCLUDED

#if defined(_RIM_VIEW) || defined(_RIM_SUN)
	#include "RimLighting.hlsl"
#endif

half3 EmissionLighting(InputData inputData, SurfaceData surfaceData, BRDF brdf, Light light)
{
	float3 normal = inputData.normalWS;
	float3 viewDir = inputData.viewDirectionWS;

	half3 color = 0.0;
	
	#if defined(_RIM_VIEW)
		half3 rimColor = RimViewLighting(viewDir, normal, surfaceData.metallic);
		color += rimColor * brdf.diffuse * light.attenuation;
	#endif

	#if defined(_RIM_SUN)
		half3 sumRimColor = RimSunLighting(viewDir, normal, light.direction);
		color += sumRimColor * light.attenuation;
	#endif

	color += surfaceData.emission;
	return color;
}

#endif