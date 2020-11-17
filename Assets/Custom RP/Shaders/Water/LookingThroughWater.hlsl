#ifndef CUSTOM_LOOKING_THROUGH_WATER_INCLUDED
#define CUSTOM_LOOKING_THROUGH_WATER_INCLUDED

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

float WaterDepth(float4 screenPos) {
	float2 uv = screenPos.xy / screenPos.w;
	float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
	float backgroundDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
	return backgroundDepth;
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	return max(0.0, backgroundDepth - surfaceDepth);
}

float3 ColorBelowWater(float4 screenPos, float2 baseUV) {
	float depth = WaterDepth(screenPos);
	return depth / 20;
}

#endif