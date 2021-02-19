#ifndef CUSTOM_BLOOM_INCLUDED
#define CUSTOM_BLOOM_INCLUDED

TEXTURE2D(_BloomLowMip);

float4 _BloomLowMip_TexelSize;
float4 _BloomThreshold;
float _BloomIntensity;

half4 GetSourceLowMip(float2 uv) {
	return SAMPLE_TEXTURE2D(_BloomLowMip, sampler_linear_clamp, uv);
}

float4 GetSourceLowMip2DBicubic(float2 uv) {
	return SampleTexture2DBicubic(TEXTURE2D_ARGS(_BloomLowMip, sampler_linear_clamp),
		uv, _BloomLowMip_TexelSize.zwxy, 1.0, 0.0);
}

half4 BloomPrefilterPassFragment(Varyings input) : SV_TARGET {
	half4 color = GetSource(input.fxUV);
	return half4(ApplyBloomThreshold(color.rgb, _BloomThreshold), 1.0);
}

half4 BloomHorizontalPassFragment(Varyings input) : SV_TARGET {
	float2 uv = input.fxUV;
	float texelSize = GetSourceTexelSize().x * 2.0;
	return BlurHorizontal(uv, TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), texelSize);
}

half4 BloomVerticalPassFragment(Varyings input) : SV_TARGET {
	float2 uv = input.fxUV;
	float texelSize = GetSourceTexelSize().y;
	return BlurVertical(uv, TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), texelSize);
}

half4 BloomAddPassFragment(Varyings input) : SV_TARGET {
	half3 highRes = GetSource(input.fxUV).rgb;
	half3 lowRes = GetSourceLowMip2DBicubic(input.fxUV).rgb;
	return half4(lowRes * _BloomIntensity + highRes, 1.0);
}

half4 BloomScatterPassFragment(Varyings input) : SV_TARGET {
	half3 highRes = GetSource(input.fxUV).rgb;
	half3 lowRes = GetSourceLowMip2DBicubic(input.fxUV).rgb;
	return half4(lerp(highRes, lowRes, _BloomIntensity), 1.0);
}

half4 BloomScatterFinalPassFragment(Varyings input) : SV_TARGET {
	half3 highRes = GetSource(input.fxUV).rgb;
	half3 lowRes = GetSourceLowMip2DBicubic(input.fxUV).rgb;
	lowRes += highRes - ApplyBloomThreshold(highRes, _BloomThreshold);
	return half4(lerp(highRes, lowRes, _BloomIntensity), 1.0);
}

#endif