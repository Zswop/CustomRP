Shader "Hidden/CustomRP/BokehDepthOfField"
{
	HLSLINCLUDE
		#include "../../ShaderLibrary/Common.hlsl"
		#include "Common.hlsl"
		
		TEXTURE2D(_BlitTex);
		TEXTURE2D(_CoCTexture);
		TEXTURE2D(_DoFTexture);
		TEXTURE2D_FLOAT(_CameraDepthTexture);

		float4 _BlitTex_TexelSize;
		float4 _CoCParams;

		#define FocusDist       _CoCParams.x
        #define MaxCoC          _CoCParams.y
        #define MaxRadius       _CoCParams.z
        #define RcpAspect       _CoCParams.w

		// rings = 3
		// points per ring = 7
		static const int kSampleCount = 22;

		static const float2 kDiskKernel[kSampleCount] = 
		{
			float2(0,0),
			float2(0.53333336,0),
			float2(0.3325279,0.4169768),
			float2(-0.11867785,0.5199616),
			float2(-0.48051673,0.2314047),
			float2(-0.48051673,-0.23140468),
			float2(-0.11867763,-0.51996166),
			float2(0.33252785,-0.4169769),
			float2(1,0),
			float2(0.90096885,0.43388376),
			float2(0.6234898,0.7818315),
			float2(0.22252098,0.9749279),
			float2(-0.22252095,0.9749279),
			float2(-0.62349,0.7818314),
			float2(-0.90096885,0.43388382),
			float2(-1,0),
			float2(-0.90096885,-0.43388376),
			float2(-0.6234896,-0.7818316),
			float2(-0.22252055,-0.974928),
			float2(0.2225215,-0.9749278),
			float2(0.6234897,-0.7818316),
			float2(0.90096885,-0.43388376),
		};

		half CoCPassFragment(Varyings input) : SV_TARGET
		{
			float2 uv = input.fxUV;
			float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_PointClamp, uv); //texture.Load
			float depth = LinearEyeDepth(rawDepth, _ZBufferParams);

			half coc = (1.0 - FocusDist/depth) * MaxCoC;
			half nearCoC = clamp(coc, -1.0, 0.0);
            half farCoC = saturate(coc);
			return saturate((nearCoC + farCoC + 1.0) * 0.5);
		}

		half4 PrefilterPassFragment(Varyings input) : SV_TARGET
		{
			float2 uv = input.fxUV;
			float2 texelSize = _BlitTex_TexelSize.xy;
			float4 d = texelSize.xyxy * float2(-0.5, 0.5).xxyy;

			half3 c0 = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv + d.xy).xyz;
			half3 c1 = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv + d.zy).xyz;
			half3 c2 = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv + d.xw).xyz;
			half3 c3 = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv + d.zw).xyz;

			half coc0 = SAMPLE_TEXTURE2D(_CoCTexture, sampler_linear_clamp, uv + d.xy).x * 2.0 - 1.0;
			half coc1 = SAMPLE_TEXTURE2D(_CoCTexture, sampler_linear_clamp, uv + d.zy).x * 2.0 - 1.0;
			half coc2 = SAMPLE_TEXTURE2D(_CoCTexture, sampler_linear_clamp, uv + d.xw).x * 2.0 - 1.0;
			half coc3 = SAMPLE_TEXTURE2D(_CoCTexture, sampler_linear_clamp, uv + d.zw).x * 2.0 - 1.0;
			
			half w0 = abs(coc0) / (Max3(c0.x, c0.y, c0.z) + 1.0);
            half w1 = abs(coc1) / (Max3(c1.x, c1.y, c1.z) + 1.0);
            half w2 = abs(coc2) / (Max3(c2.x, c2.y, c2.z) + 1.0);
            half w3 = abs(coc3) / (Max3(c3.x, c3.y, c3.z) + 1.0);
			
            half3 avg = c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3;
            avg /= max(w0 + w1 + w2 + w3, 1e-5);
			
			//half3 avg = (c0 + c1 + c2 + c3) * 0.25;
			//return half4(avg, 1.0);

            half cocMin = min(coc0, Min3(coc1, coc2, coc3));
            half cocMax = max(coc0, Max3(coc1, coc2, coc3));
			//return cocMax;

            half coc = (-cocMin > cocMax ? cocMin : cocMax) * MaxRadius;
			//return coc * 1000.0;

            avg *= smoothstep(0, texelSize.y * 2.0, abs(coc));
			return half4(avg, coc);
		}

		half4 BokehBlurPassFragment(Varyings input) : SV_TARGET
		{
			float2 uv = input.fxUV;
			half4 samp0 = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv);

			half4 farAcc = 0.0;
            half4 nearAcc = 0.0;

			UNITY_LOOP
			for (int k = 0; k < kSampleCount; k++) 
			{
				float2 disp = kDiskKernel[k].xy * MaxRadius;
				float dist = length(disp);

				float2 duv = float2(disp.x * RcpAspect, disp.y);
				half4 samp = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv + duv);

				half farCoC = max(min(samp0.a, samp.a), 0.0);

				const half margin = _BlitTex_TexelSize.y * 2.0;
				half farWeight = saturate((farCoC - dist + margin) / margin);
				half nearWeight = saturate((-samp.a - dist + margin) / margin);
				nearWeight *= step(_BlitTex_TexelSize.y, -samp.a);

				farAcc += half4(samp.rgb, 1.0) * farWeight;
				nearAcc += half4(samp.rgb, 1.0) * nearWeight;
			}
			
            farAcc.rgb /= farAcc.a + (farAcc.a == 0.0);
            nearAcc.rgb /= nearAcc.a + (nearAcc.a == 0.0);
			//return nearAcc;

			nearAcc.a *= PI / kSampleCount;
            half alpha = saturate(nearAcc.a);
            half3 rgb = lerp(farAcc.rgb, nearAcc.rgb, alpha);
            return half4(rgb, alpha);
		}

		half4 PostBlurPassFragment(Varyings input) : SV_TARGET
		{
			float2 uv = input.fxUV;
			float2 texelSize = _BlitTex_TexelSize.xy;
			return SampleBox4(uv, TEXTURE2D_ARGS(_BlitTex, sampler_linear_clamp), texelSize, 0.5);
		}

		half4 FinalPassFragment(Varyings input) : SV_TARGET
		{
			float2 uv = input.fxUV;
			half4 dof = SAMPLE_TEXTURE2D(_DoFTexture, sampler_linear_clamp, uv);
            half coc = SAMPLE_TEXTURE2D(_CoCTexture, sampler_linear_clamp, uv).r;
            coc = (coc - 0.5) * 2.0 * MaxRadius;
            
			half4 color = SAMPLE_TEXTURE2D(_BlitTex, sampler_linear_clamp, uv);
            float ffa = smoothstep(_BlitTex_TexelSize.y * 2.0, _BlitTex_TexelSize.y * 4.0, coc);
			//return lerp(color, dof, ffa);

			half alpha = Max3(dof.r, dof.g, dof.b);
            color = lerp(color, half4(dof.rgb, alpha), ffa + dof.a - ffa * dof.a);
			return color;
		}

	ENDHLSL

	SubShader
	{
		Cull Off
		ZTest Always
		ZWrite Off
		
		Pass
		{
			Name "CoC"
			HLSLPROGRAM
			#pragma vertex DefaultPassVertex
			#pragma fragment CoCPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "Prefilter"
			HLSLPROGRAM
			#pragma vertex DefaultPassVertex
			#pragma fragment PrefilterPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "BokehBlur"
			HLSLPROGRAM
			#pragma vertex DefaultPassVertex
			#pragma fragment BokehBlurPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "PostBlur"
			HLSLPROGRAM
			#pragma vertex DefaultPassVertex
			#pragma fragment PostBlurPassFragment
			ENDHLSL
		}

		Pass
		{
			Name "FinalPass"
			HLSLPROGRAM
			#pragma vertex DefaultPassVertex
			#pragma fragment FinalPassFragment
			ENDHLSL
		}
	}
}