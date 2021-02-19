Shader "Hidden/CustomRP/PostFXStack"
{
	SubShader
	{
		Cull Off
		ZTest Always
		ZWrite Off

		HLSLINCLUDE
			#include "../../ShaderLibrary/Common.hlsl"
			#include "../../ShaderLibrary/Sampling.hlsl"

			#include "Common.hlsl"
			#include "PostFXStackPasses.hlsl"
		ENDHLSL

		Pass
		{
			Name "Depth Stripes"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment DepthStripesPassFragment

			#include "../../ShaderLibrary/DeclareDepthTexture.hlsl"

			half4 DepthStripesPassFragment(Varyings input) : SV_TARGET {
				float rawDepth = SampleCameraDepth(input.fxUV);
				half4 color = GetSource(input.fxUV);

				#if UNITY_REVERSED_Z
					bool hasDepth = rawDepth != 0;
				#else
					bool hasDepth = rawDepth != 1;
				#endif

				if (hasDepth) {
					float depth = LinearEyeDepth(rawDepth, _ZBufferParams);
					color *= pow(sin(3.14 * depth), 2.0);
				}
				return color;
			}
			ENDHLSL
		}

		Pass
		{
			Name "Blur"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BlurPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Prefilter"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomPrefilterPassFragment
			#include "Bloom.hlsl"
			ENDHLSL
		}
		
		Pass
		{
			Name "Bloom Horizontal"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomHorizontalPassFragment
			#include "Bloom.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Vertical"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomVerticalPassFragment
			#include "Bloom.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Scatter"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomScatterPassFragment
			#include "Bloom.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Add"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomAddPassFragment
			#include "Bloom.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Scatter Final"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomScatterFinalPassFragment
			#include "Bloom.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "Copy"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment CopyPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Color Grading"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment ColorGradingPassFragment
			#include "ColorGrading.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "ColorGraded ACES"

			HLSLPROGRAM
			#pragma target 3.5
			#define _TONEMAP_ACES
			#pragma vertex DefaultPassVertex
			#pragma fragment ColorGradedACESPassFragment
			#include "ColorGrading.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "ColorGraded Neutral"

			HLSLPROGRAM
			#pragma target 3.5
			#define _TONEMAP_NEUTRAL
			#pragma vertex DefaultPassVertex
			#pragma fragment ColorGradedNeutralPassFragment
			#include "ColorGrading.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "FXAA"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment FXAAPassFragment
			#include "FXAA.hlsl"
			ENDHLSL
		}
	}
}