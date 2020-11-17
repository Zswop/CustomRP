Shader "OpenCS/CustomRP/DistortionWater"
{
	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows("Receive Shadows", Float) = 1

		[Header(Flow)]
		[Toggle(_NORMAL_MAP)] _NormalMapToggle("Normal Map", Float) = 0
		[NoScaleOffset] _DerivHeightMap ("Deriv (AG) Height (B)", 2D) = "black" {}
		[NoScaleOffset] _FlowMap ("Flow (RG, B Strength, A noise)", 2D) = "black" {}		
		_UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling ("Tiling", Float) = 1
		_Speed ("Speed", Float) = 1
		_FlowStrength ("Flow Strength", Float) = 1
		_FlowOffset ("Flow Offset", Float) = 0
		_HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75

		[Header(Wave)]
		[Toggle(_GERSTNER_WAVE)] _WaveToggle("Water Wave", Float) = 0
		_WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
		_WaveB ("Wave B (dir, steepness, wavelength)", Vector) = (0, 1, 0.25, 20)
		_WaveC ("Wave C (dir, steepness, wavelength)", Vector) = (1, 1, 0.15, 10)

		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha("Premultiply Alpha", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
	}

	SubShader
	{
		HLSLINCLUDE
		#include "../../ShaderLibrary/Common.hlsl"
		#include "Flow.hlsl"
		ENDHLSL

		Pass 
		{
			Tags {
				"LightMode" = "CustomLit"
			}
			
			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			HLSLPROGRAM			
			#pragma target 3.5
			//#pragma shader_feature _CLIPPING
			#pragma shader_feature _RECEIVE_SHADOWS
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _GERSTNER_WAVE

			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			//#pragma multi_compile _ _LIGHTS_PER_OBJECT
			//#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7

			#pragma vertex WaterPassVertex
			#pragma fragment WaterPassFragment
			#include "DistortionWaterInput.hlsl"
			#include "WaterCommonPass.hlsl"
			ENDHLSL
		}
	}

	CustomEditor "OpenCS.CustomShaderGUI"
}