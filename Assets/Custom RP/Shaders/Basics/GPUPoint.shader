Shader "CustomRP/Basics/GPUPoint"
{
	SubShader
	{
		HLSLINCLUDE
			#include "../../ShaderLibrary/Common.hlsl"

			struct Attributes
			{
				float3 positionOS : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : VAR_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			#if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
				StructuredBuffer<float3> _Positions;
			#endif

			float2 _Scale;

			void ConfigureProcedural () 
			{
				#if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
					float3 position = _Positions[unity_InstanceID];

					unity_ObjectToWorld = 0.0;
					unity_ObjectToWorld._m03_m13_m23_m33 = float4(position, 1.0);
					unity_ObjectToWorld._m00_m11_m22 = _Scale.x;

					unity_WorldToObject = 0.0;
					unity_WorldToObject._m03_m13_m23_m33 = float4(-position, 1.0);
					unity_WorldToObject._m00_m11_m22 = _Scale.y;
				#endif
			}

			Varyings vert(Attributes input)
			{
				Varyings output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionWS = TransformObjectToWorld(input.positionOS);
				output.positionCS = TransformWorldToHClip(output.positionWS);
				return output;
			}
		ENDHLSL

		Pass
		{
			Tags {
				"LightMode" = "CustomLit"
			}

			HLSLPROGRAM
			#pragma target 4.5
			#pragma multi_compile_instancing
			#pragma instancing_options procedural:ConfigureProcedural
			#pragma editor_sync_compilation

			#pragma vertex vert
			#pragma fragment frag

			half4 frag(Varyings input) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);
				half3 albedo = saturate(input.positionWS * 0.5 + 0.5);
				return half4(albedo, 1.0);
			}			
			ENDHLSL
		}

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 4.5
			#pragma multi_compile_instancing
			#pragma instancing_options procedural:ConfigureProcedural
			#pragma editor_sync_compilation

			#pragma vertex vert
			#pragma fragment frag

			half4 frag(Varyings input) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);
				return 0;
			}
			ENDHLSL
		}
	
	}
}