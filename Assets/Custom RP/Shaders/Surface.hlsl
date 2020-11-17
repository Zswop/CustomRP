#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct SurfaceData
{
	float3 albedo;
	float alpha;
	float cutoff;
	
	float metallic;
	float occlusion;
	float smoothness;
	float fresnel;
	
	float3 normalTS;
	float3 emission;

	#if defined(DISTORTION_FLOW)

	#endif
};

#endif