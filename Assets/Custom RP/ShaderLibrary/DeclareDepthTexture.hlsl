#ifndef CUSTOM_DEPTH_TEXTURE_INCLUDED
#define CUSTOM_DEPTH_TEXTURE_INCLUDED

TEXTURE2D_FLOAT(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

float SampleCameraDepth(float2 uv)
{
    return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
}

#endif