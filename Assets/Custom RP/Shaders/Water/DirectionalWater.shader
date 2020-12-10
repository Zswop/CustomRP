Shader "OpenCS/CustomRP/DirectionalWater"
{
	Properties
	{
		_BaseMap ("Deriv (AG) Height (B)", 2D) = "black" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows("Receive Shadows", Float) = 1

		[Toggle(_NORMAL_MAP)] _NormalMapToggle("Normal Map", Float) = 0
		[NoScaleOffset] _FlowMap ("Flow (RG, B Strength, A noise)", 2D) = "black" {}

		[Header(Directional Flow)]
		_Tiling ("Tiling Constant", Float) = 1
		_TilingModulated ("Tiling, Modulated", Float) = 1
		_GridResolution ("Grid Resolution", Float) = 10
		_Speed ("Speed", Float) = 1
		_FlowStrength ("Flow Strength", Float) = 1
		_HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75

		[Header(Below Water)]
		_WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity("Water Fog Density", Range(0, 2)) = 0.1
		_RefractionStrength ("Refraction Strength", Range(0, 1)) = 0.25

		[Header(Wave)]
		[Toggle(_GERSTNER_WAVE)] _WaveToggle("Water Wave", Float) = 0
		_WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
		_WaveB ("Wave B (dir, steepness, wavelength)", Vector) = (0, 1, 0.25, 20)
		_WaveC ("Wave C (dir, steepness, wavelength)", Vector) = (1, 1, 0.15, 10)
	}

	SubShader
	{
		HLSLINCLUDE
		#include "../../ShaderLibrary/Common.hlsl"
		#include "Flow.hlsl"
		ENDHLSL

		Tags { "RenderType"="Opaque" "Queue"="Transparent-100" "RenderPipeline" = "CustomPipeline" }

		Pass
		{
			Tags {
				"LightMode" = "CustomLit"
			}

			//Blend One Zero
			ZWrite Off
			Cull Off

			HLSLPROGRAM
			#pragma vertex WaterPassVertex
			#pragma fragment WaterPassFragment

			#pragma target 3.5
			#pragma shader_feature _RECEIVE_SHADOWS
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _GERSTNER_WAVE

			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			//#pragma multi_compile _ _LIGHTS_PER_OBJECT
			//#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7

			#define _PREMULTIPLY_ALPHA

			#include "DirectionalWaterInput.hlsl"
			#include "WaterCommonPass.hlsl"
			ENDHLSL
		}
	}

	CustomEditor "OpenCS.CustomShaderGUI"
}