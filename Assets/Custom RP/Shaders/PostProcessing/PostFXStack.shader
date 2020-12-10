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
			ENDHLSL
		}
		
		Pass
		{
			Name "Bloom Horizontal"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomHorizontalPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Vertical"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomVerticalPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Scatter"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomScatterPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Add"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomAddPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Bloom Scatter Final"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment BloomScatterFinalPassFragment
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
			ENDHLSL
		}

		Pass
		{
			Name "ColorGraded ACES"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment ColorGradedACESPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "ColorGraded Neutral"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment ColorGradedNeutralPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "ColorGraded Final"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment ColorGradingFinalPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "FXAA Luminance"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment FXAALuminancePassFragment
			ENDHLSL
		}

		Pass
		{
			Name "FXAA"

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex DefaultPassVertex
			#pragma fragment FXAAPassFragment
			ENDHLSL
		}
	}
}