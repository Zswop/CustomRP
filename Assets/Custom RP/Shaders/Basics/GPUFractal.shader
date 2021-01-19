Shader "CustomRP/Basics/GPUFractal"
{
	Properties
	{
		_Color("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
	}

	SubShader
	{
		HLSLINCLUDE
			#include "../../ShaderLibrary/Common.hlsl"

			struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;

				float3 normalWS : VAR_NORMAL;
				float3 positionWS : VAR_POSITION;				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			#if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
				#if defined(_MATRIX_3X4)
					StructuredBuffer<float3x4> _Matrices;
				#else
					StructuredBuffer<float4x4> _Matrices;
				#endif
			#endif
			
			void ConfigureProcedural () 
			{
				#if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
					#if defined(_MATRIX_3X4)
						float3x4 m = _Matrices[unity_InstanceID];
						unity_ObjectToWorld._m00_m01_m02_m03 = m._m00_m01_m02_m03;
						unity_ObjectToWorld._m10_m11_m12_m13 = m._m10_m11_m12_m13;
						unity_ObjectToWorld._m20_m21_m22_m23 = m._m20_m21_m22_m23;
						unity_ObjectToWorld._m30_m31_m32_m33 = float4(0.0, 0.0, 0.0, 1.0);
					#else
						unity_ObjectToWorld = _Matrices[unity_InstanceID];
					#endif
				#endif
			}

			Varyings vert(Attributes input)
			{
				Varyings output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionWS = TransformObjectToWorld(input.positionOS);
				output.positionCS = TransformWorldToHClip(output.positionWS);
				output.normalWS = TransformObjectToWorldNormal(input.normalOS);
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
			#pragma instancing_options assumeuniformscaling procedural:ConfigureProcedural
			#pragma editor_sync_compilation

			#pragma multi_compile_local _ _MATRIX_3X4
			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			
			#define _RECEIVE_SHADOWS

			#pragma vertex vert
			#pragma fragment frag

			#include "../Surface.hlsl"
			#include "../LitPassCommon.hlsl"

			CBUFFER_START(UnityPerMaterial)
				half4 _Color;
				half _Smoothness;
			CBUFFER_END

			inline void InitializeSurfaceData(float2 uv, out SurfaceData surfaceData) {
				ZERO_INITIALIZE(SurfaceData, surfaceData)

				float4 base = _Color;
				surfaceData.albedo = base.rgb;
				surfaceData.alpha = base.a;
				surfaceData.normalTS = float3(0.0, 0.0, 1.0);

				surfaceData.smoothness = _Smoothness;
				surfaceData.metallic = 0.0;
				surfaceData.occlusion = 1.0;
				surfaceData.fresnel = 1.0;
				surfaceData.emission = 0.0;
			}

			inline void InitializeInputData(Varyings input, out InputData inputData) {
				ZERO_INITIALIZE(InputData, inputData)

				inputData.normalWS = normalize(input.normalWS);
				inputData.positionWS = input.positionWS;

				inputData.interpolatedNormalWS = input.normalWS.xyz;
				inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - inputData.positionWS.xyz);
				inputData.depthVS = -TransformWorldToView(inputData.positionWS.xyz).z;
				inputData.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

				inputData.bakedGI = SAMPLE_GI(float2(0.0, 0.0), inputData.normalWS);
			}

			half4 frag(Varyings input) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);

				SurfaceData surfaceData;
				InitializeSurfaceData(float2(0.0, 0.0), surfaceData);

				InputData inputData;
				InitializeInputData(input, inputData);

				half3 color = CustomLighting(inputData, surfaceData);
				return half4(color, surfaceData.alpha);
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
			#pragma instancing_options assumeuniformscaling procedural:ConfigureProcedural
			#pragma editor_sync_compilation

			#pragma multi_compile_local _ _MATRIX_3X4

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