Shader "OpenCS/CustomRP/Terrain/UnlitSurface"
{
	Properties
	{
		[HDR] _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_BaseMap("Texture", 2D) = "white"{ }
	}

	SubShader
	{
		HLSLINCLUDE
			#include "../../ShaderLibrary/Common.hlsl"
		ENDHLSL

		Pass
		{
			HLSLPROGRAM
			#pragma vertex TerrainSurfaceVertex
			#pragma fragment TerrainSurfaceFragment

			struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 baseUV : TEXCOORD0;
				half4 color : COLOR;
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : VAR_NORMAL;
				float2 baseUV : VAR_BASE_UV;
				half4 color : VAR_VERTEX_COLOR;
			};

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseMap_ST;
				float4 _BaseColor;
			CBUFFER_END

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			Varyings TerrainSurfaceVertex(Attributes input)
			{
				Varyings output;

				output.positionCS = TransformObjectToHClip(input.positionOS);
				output.normalWS = TransformObjectToWorldNormal(input.normalOS);
				output.baseUV = TRANSFORM_TEX(input.baseUV, _BaseMap);
				output.color = input.color;
				return output;
			}

			half4 TerrainSurfaceFragment(Varyings input) : SV_TARGET
			{
				half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV) * _BaseColor;
				albedo *= input.color;
				return albedo;
			}

			ENDHLSL
		}
	}
}