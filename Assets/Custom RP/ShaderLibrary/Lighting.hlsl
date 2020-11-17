#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

half3 GetIncomingLight(Light light, float3 normal) {
	return saturate(dot(normal, light.direction) * light.attenuation) * light.color;
}

half3 GetLighting(BRDF brdf, Light light, float3 normal, float3 viewDirection) {
	return GetIncomingLight(light, normal) * DirectBRDF(brdf, light.direction, normal, viewDirection);
}

half3 GetIndirectLighting(BRDF brdf, half3 bakedGI, half3 indirectSpec,	half occlusion, 
	float3 normal, float3 viewDirection) {
	half3 diffuse = bakedGI * occlusion;
	half3 specular = indirectSpec * occlusion;
	return IndirectBRDF(brdf, diffuse, specular, normal, viewDirection);
}

#endif