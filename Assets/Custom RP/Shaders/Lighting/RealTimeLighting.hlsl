#ifndef CUSTOM_REALTIME_LIGHTING_INCLUDED
#define CUSTOM_REALTIME_LIGHTING_INCLUDED

#if defined(_MESH_HAIR)
	#include "MeshHairLighting.hlsl"
#endif

#if defined(_TOON_SKIN)
	#include "ToonSkinLighting.hlsl"
#endif

half3 RealTimeLighting(InputData inputData, SurfaceData surfaceData, BRDF brdf, Light light)
{
	half3 normal = inputData.normalWS;
	half3 tangent = inputData.tangentWS;
	half3 viewDirection = inputData.viewDirectionWS;

	half3 diffuseColor = brdf.diffuse;
	half3 specularColor = brdf.specular;

	half3 color = 0.0;
#if !defined(_DIFFUSE_OFF)
	color += GetLambertDiffuse(diffuseColor, light, normal, viewDirection);
#endif

#if defined(_MESH_HAIR)
	color += MeshHairDiffuse(diffuseColor, light, normal, viewDirection);
#endif

#if defined(_TOON_SKIN)
	color += ToonSkinDiffuse(diffuseColor, light, normal, viewDirection);
#endif

#if !defined(_SPECULAR_OFF)
	 color += GetBRDFSpecular(brdf, light, normal, viewDirection);
#endif

#if defined(_MESH_HAIR)
	color += MeshHairSpecualr(diffuseColor, light, tangent, normal, viewDirection,
		surfaceData.specShift, surfaceData.specMask);
#endif

	return color;
}

#endif