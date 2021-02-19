#ifndef CUSTOM_FOG_INCLUDED
#define CUSTOM_FOG_INCLUDED

#define DISTANCE_FOG_LINEAR

//fog global input
half _FogThickness;

// x = density / sqrt(ln(2)), useful for Exp2 mode
// y = density / ln(2), useful for Exp mode
// z = -1/(end-start), useful for Linear mode
// w = end/(end-start), useful for Linear mode
half4 _DistanceFogParams;
half4 _DistanceFogColor;

// x = thickness
// y = falloff
// z = base height
// w = distace falloff
half4 _HeightFogParams;
half4 _HeightFogColor;

float CalculateDistanceFogFactor(float viewDistance) {
	float fogFactor = 0.0;
#if defined(DISTANCE_FOG_LINEAR)
	fogFactor = viewDistance * _DistanceFogParams.z + _DistanceFogParams.w;
#elif defined(DISTANCE_FOG_EXP)
	fogFactor = exp2(-viewDistance * _DistanceFogParams.y);
#elif defined(DISTANCE_FOG_EXP2)
	fogFactor = viewDistance * _DistanceFogParams.x;
	fogFactor = exp2(-fogFactor * fogFactor);
#endif
	return fogFactor;
}

float CalculateHeightFogFactor(float viewDistance, float3 viewDirection) {
	float height = _WorldSpaceCameraPos.y - _HeightFogParams.z;

	float ditanceFalloff = viewDistance * viewDirection.y * _HeightFogParams.w;
	ditanceFalloff = (1.0 - exp2(- ditanceFalloff)) / viewDirection.y;

	float fogFactor = exp2(-height * _HeightFogParams.y) * ditanceFalloff;
	fogFactor = min(fogFactor, _HeightFogParams.x);
	return fogFactor;
}

half3 ComputeDistanceHeightMieFogFactor(float3 positionWS) {
	float3 viewVector = positionWS.xyz - _WorldSpaceCameraPos.xyz;
	float viewDistance = length(viewVector);
	float3 viewDirection = viewVector / viewDistance;

	half3 fogCoord = 0.0;

	float distanceFogFactor = CalculateDistanceFogFactor(viewDistance);
	distanceFogFactor = min(distanceFogFactor, _FogThickness);
	fogCoord.x = distanceFogFactor;

	float heightFogFactor = CalculateHeightFogFactor(viewDistance, viewDirection);
	fogCoord.y = heightFogFactor;
	return saturate(fogCoord);
}

half3 ApplyDistanceHeightMieFog(half3 fragColor, half3 fogCoord) {
	half3 distanceFogColor = lerp(fragColor.rgb, _DistanceFogColor.rgb, fogCoord.x);
	//return distanceFogColor;

	half3 heightFogColor = lerp(fragColor.rgb, _HeightFogColor.rgb, fogCoord.y);
	//return heightFogColor;

	return lerp(distanceFogColor, heightFogColor, fogCoord.y);
}

half3 ComputeFogFactor(float3 positionWS) {
#if defined(CUSTOM_FOG)
	return ComputeDistanceHeightMieFogFactor(positionWS);
#else
	return 0.0;
#endif
}

half3 ApplyFog(half3 fragColor, half3 fogCoord) {
#if defined(CUSTOM_FOG)
	return ApplyDistanceHeightMieFog(fragColor, fogCoord);
#else
	return fragColor;
#endif
}

#endif