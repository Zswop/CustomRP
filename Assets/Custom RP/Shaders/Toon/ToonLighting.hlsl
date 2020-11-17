#ifndef CUSTOM_TOON_LIGHTING_INCLUDED
#define CUSTOM_TOON_LIGHTING_INCLUDED

half3 LightingSpecular(half3 specColor, half smoothness, float ndoth, float lightIntensity) {
	float shininess = exp2(10 * smoothness + 1);
	float specularIntensity = pow(ndoth * lightIntensity, shininess);
	float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
	half3 specular = specularIntensitySmooth * specColor;
	return specular;
}

half3 GetRimViewLighting(half3 rimColor, half3 viewDir, half3 normal) {
	half3 rimLightDir = half3(viewDir.z, viewDir.y, -viewDir.x);
	half rimDiff = max(0, dot(normal, rimLightDir));
	rimDiff = (rimDiff * rimDiff) * (rimDiff * rimDiff) * rimDiff;
	return rimColor.rgb * rimDiff;
}

half3 GetRimLighting(half3 rimColor, float rimAmount, float rimStrength, float ndotv, float ndotl) {
	float rimIntensity = (1 - ndotv) * pow(saturate(ndotl), rimStrength);
	float rimIntensitySmooth = smoothstep(rimAmount - 0.01, rimAmount + 0.01, rimIntensity);
	half3 rim = rimIntensitySmooth * rimColor;
	return rim;
}

/*
half3 GetToonLighting(Surface surface, Light light, float ndotl, float ndoth)
{
	// TODO: ramp texture
	float lightIntensity = smoothstep(0, 0.01, ndotl * light.attenuation);

	half3 specularColor = 1.0f;
	half3 diffuse = lightIntensity * light.color * surface.albedo;
	half3 specular = LightingSpecular(specularColor, surface.smoothness, ndoth, lightIntensity);	
	return diffuse + specular;
}

half3 GetToonSkinLighting(Surface surface, Light light, float ndotl, float ndoth,
	half3 scatterColor, float wrap, float scatterWidth)
{
	float ndotlWrap = (ndotl + wrap) / (1 + wrap);
	float scatter = smoothstep(0, scatterWidth, ndotlWrap) * 
		smoothstep(scatterWidth * 2, scatterWidth, ndotlWrap);

	half3 diffuseColor = scatterColor * scatter + surface.albedo;
	return diffuseColor * light.attenuation * light.color;
}

half3 GetLighting(Surface surfaceWS, GI gi, float3 rimColor, float rimAmount, float rimStrength)
{
	ShadowData shadowData = GetShadowData(surfaceWS);

	half3 color = gi.diffuse * surfaceWS.albedo;
	for (int i = 0; i < GetDirectionalLightCount(); ++i) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		
		float ndotl = dot(surfaceWS.normal, light.direction);
		float ndotv = dot(surfaceWS.normal, surfaceWS.viewDirection);
		float3 halfVector = normalize(surfaceWS.viewDirection + light.direction);
		float ndoth = saturate(dot(surfaceWS.normal, halfVector));

		color += GetToonLighting(surfaceWS, light, ndotl, ndoth);
		color += GetRimLighting(rimColor, rimAmount, rimStrength, ndotv, ndotl);
	}

	//color += GetRimViewLighting(rimColor.rgb, surfaceWS.viewDirection, surfaceWS.normal) * surfaceWS.albedo;
	return color;
}
*/

#endif