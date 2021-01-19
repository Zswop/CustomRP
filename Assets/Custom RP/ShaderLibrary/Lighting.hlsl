#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

half3 GetIncomingLight(Light light, float3 normal) {
	return saturate(dot(normal, light.direction) * light.attenuation) * light.color;
}

half3 GetLighting(BRDF brdf, Light light, float3 normal, float3 viewDirection) {
	return GetIncomingLight(light, normal) * DirectBRDF(brdf, light.direction, normal, viewDirection);
}

half3 GetLambertDiffuse(half3 diffuseColor, Light light, float3 normal, float3 viewDirection) {
	return GetIncomingLight(light, normal) * diffuseColor;
}

half3 GetBRDFSpecular(BRDF brdf, Light light, float3 normal, float3 viewDirection) {
	return GetIncomingLight(light, normal) * DirectBRDFSpecular(brdf, light.direction, normal, viewDirection);
}

half3 GetBRDFIndirect(BRDF brdf, half3 diffuse, half3 specular, float3 normal, float3 viewDirection, half fresnel) {
	return IndirectBRDF(brdf, diffuse, specular, normal, viewDirection, fresnel);
}

#endif