#ifndef CUSTOM_DECLARE_OPAQUE_TEXTURE_INCLUDED
#define CUSTOM_DECLARE_OPAQUE_TEXTURE_INCLUDED

TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

half3 SampleCameraOpaqueColor(float2 uv)
{
    return SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv).rgb;
}

#endif