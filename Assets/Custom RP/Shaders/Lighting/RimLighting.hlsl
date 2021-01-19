#ifndef CUSTOM_RIM_LIGHTING_INCLUDED
#define CUSTOM_RIM_LIGHTING_INCLUDED

#if defined(_RIM_VIEW)
half3 RimViewLighting(half3 viewDir, half3 normal, half metallic) {
	half3 rimLightDir = half3(viewDir.z, viewDir.y, -viewDir.x);
	half mask = metallic + _RimViewMask;

	half rimDiff = max(0.0, dot(normal, rimLightDir));
    rimDiff = (rimDiff * rimDiff) * (rimDiff * rimDiff) * rimDiff;
	return _RimViewColor.rgb * rimDiff * mask;
}
#endif

#if defined(_RIM_SUN)
half3 RimSunLighting(half3 viewDir, half3 normal, half3 lightDir) {
	half rim = 1.0 - saturate(dot(viewDir, normal));
	half intensity = pow(rim, _RimSunPower) * _RimSunIntensity;
	intensity = smoothstep(0.2, 1.0, intensity);
	return _RimSunColor.rgb * intensity * saturate(dot(lightDir, normal));
}
#endif

#endif