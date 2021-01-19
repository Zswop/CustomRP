#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct SurfaceData
{
	half3 albedo;
	half alpha;
	
	half metallic;
	half occlusion;
	half smoothness;
	half fresnel;

	half3 normalTS;
	half3 emission;

	half specShift;
	half specMask;
};

half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0)
{
#if defined(_NORMAL_MAP)
    half4 map = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
	return DecodeNormal(map, scale);
#else
    return half3(0.0, 0.0, 1.0);
#endif
}

half4 SampleMODSMask(float2 uv, TEXTURE2D_PARAM(maskMap, sampler_maskMap), half4 mods)
{
#if defined(_MASK_MAP)
	half4 map = SAMPLE_TEXTURE2D(maskMap, sampler_maskMap, uv);
	return mods * map + half4(0.0, 1.0 - mods.g, 0.0, 0.0);
#endif
	return mods;
}

half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
{
    return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgb * emissionColor;
}

half Alpha(half albedoAlpha, half cutoff)
{
#if defined(_CLIPPING)
	clip(albedoAlpha - cutoff);
#endif
	return albedoAlpha;
}

#endif