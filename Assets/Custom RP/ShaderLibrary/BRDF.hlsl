#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED

#define MIN_REFLECTIVITY 0.04

struct BRDF {
	float3 diffuse;
	float3 specular;
	float perceptualRoughness;
	float roughness;
	float fresnel;
};

float OneMinusReflectivity(float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF(float3 albedo, float metallic, float smoothness, float alpha = 1.0f) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(metallic);

	brdf.diffuse = albedo * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, albedo, metallic);

#if defined(_PREMULTIPLY_ALPHA)
	brdf.diffuse *= alpha;
#endif

	brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
	brdf.fresnel = saturate(smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

float SpecularStrength(BRDF brdf, float3 lightDirection, float3 normal, float3 viewDirection) {
	float3 h = SafeNormalize(lightDirection + viewDirection);
	float nh2 = Square(saturate(dot(normal, h)));
	float lh2 = Square(saturate(dot(lightDirection, h)));
	float r2 = Square(brdf.roughness);
	float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
	float normalization = brdf.roughness * 4.0 + 2.0;
	float specularTerm = r2 / (d2 * max(0.1, lh2) * normalization);
	return specularTerm;
}

float3 DirectBRDFSpecular(BRDF brdf, float3 lightDirection, float3 normal, float3 viewDirection) {
	return SpecularStrength(brdf, lightDirection, normal, viewDirection) * brdf.specular;
}

float3 DirectBRDF(BRDF brdf, float3 lightDirection, float3 normal, float3 viewDirection) {
	return SpecularStrength(brdf, lightDirection, normal, viewDirection) * brdf.specular + brdf.diffuse;
}

float3 IndirectBRDF(BRDF brdf, float3 diffuse, float3 specular, float3 normal, float3 viewDirection, half fresnel) {
	float fresnelStrength = fresnel * Pow4(1.0 - saturate(dot(normal, viewDirection)));
	float3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
	reflection /= (brdf.roughness * brdf.roughness + 1.0);
	return diffuse * brdf.diffuse + reflection;
}

float3 IndirectBRDFApprox(BRDF brdf, float3 diffuse, float3 specular, float3 normal, float3 viewDirection) {
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	const float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
	const float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);
	float ndotv = saturate(dot(normal, viewDirection));

	float4 r = brdf.roughness * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * ndotv)) * r.x + r.y;
	float2 AB = float2(-1.04h, 1.04h) * a004 + r.zw;
	float3 specularTerm = brdf.specular * AB.x + AB.y;
	return diffuse * brdf.diffuse + specularTerm * specular;
}

#endif