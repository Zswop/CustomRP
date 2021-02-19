#ifndef CUSTOM_POST_FX_PASSES_INCLUDED
#define CUSTOM_POST_FX_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

#define _PostFXSource _BlitTex
#define _PostFXSource_TexelSize _BlitTex_TexelSize;

TEXTURE2D(_PostFXSource);
float4 _PostFXSource_TexelSize;

float4 GetSourceTexelSize() {
	return _PostFXSource_TexelSize;
}

half4 GetSource(float2 uv) {
	return SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, uv);
}

half4 CopyPassFragment(Varyings input) : SV_TARGET {
	return GetSource(input.fxUV);
}

//Blur

float _BlurRadius;

half4 BlurPassFragment(Varyings input) : SV_TARGET {
	float2 uv = input.fxUV;
	float4 texelSize =  GetSourceTexelSize();
    return SampleBox4(uv, TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), texelSize.xy, _BlurRadius);
}

#endif