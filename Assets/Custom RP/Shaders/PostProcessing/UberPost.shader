Shader "Hidden/CustomRP/UberPost"
{
    HLSLINCLUDE

    #pragma multi_compile_local _ _BLOOM_ADD _BLOOM_SCATTER
    #pragma multi_compile_local _ _VIGNETTE

    #include "../../ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
    #include "Common.hlsl"

    #if _BLOOM_ADD || _BLOOM_SCATTER
        #define BLOOM
    #endif

    TEXTURE2D(_BlitTex);
    TEXTURE2D(_BloomTexture);
    TEXTURE2D(_LUTTexture);

    float _BloomIntensity;
    float4 _BloomThreshold;
    float4 _BloomTexture_TexelSize;
    float4 _ColorGradingLUTParameters;
    float4 _VignetteParams1;
    float4 _VignetteParams2;

    #define VignetteColor           _VignetteParams1.xyz
    #define VignetteCenter          _VignetteParams2.xy
    #define VignetteIntensity       _VignetteParams2.z
    #define VignetteSmoothness      _VignetteParams2.w
    #define VignetteRoundness       _VignetteParams1.w

    half4 Frag(Varyings input) : SV_Target
    {
        float2 uv = input.fxUV;
        half3 color = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv).rgb;

        #if defined(BLOOM)
        {
            half3 bloom = SampleTexture2DBicubic(TEXTURE2D_ARGS(_BloomTexture, sampler_linear_clamp),
		        uv, _BloomTexture_TexelSize.zwxy, 1.0, 0.0).rgb;
            #if defined(_BLOOM_SCATTER)
	            bloom += color - ApplyBloomThreshold(color, _BloomThreshold);
                color = lerp(color, bloom, _BloomIntensity);
            #else
                color += bloom * _BloomIntensity;
            #endif
        }
        #endif

        #if defined(_VIGNETTE)
            color = ApplyVignette(color, VignetteColor, uv, VignetteCenter, VignetteIntensity,
                VignetteRoundness, VignetteSmoothness);
        #endif

        // Color grading is always enabled when post-processing/uber is active
        {
            color = ApplyColorGradingLUT(color, TEXTURE2D_ARGS(_LUTTexture, sampler_linear_clamp), 
               _ColorGradingLUTParameters.xyz);
        }
        return half4(color, 1.0);
    }

    ENDHLSL

    SubShader
    {
        LOD 100
        ZTest Always 
        ZWrite Off 
        Cull Off

        Pass
        {
            Name "UberPost"

            HLSLPROGRAM
            #pragma vertex DefaultPassVertex
            #pragma fragment Frag
            ENDHLSL
        }
    }
}