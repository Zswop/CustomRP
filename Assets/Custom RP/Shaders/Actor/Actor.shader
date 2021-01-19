Shader "CustomRP/Actor/Actor"
{
	Properties {
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping("Alpha Clipping", Float) = 0
		[Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows("Receive Shadows", Float) = 1
		[KeywordEnum(On, Clip, Dither, Off)] _Shadows("Shadows", Float) = 0

		[Toggle(_NORMAL_MAP)] _NormalMapToggle("Normal Map", Float) = 0
		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range(0, 1)) = 1

		//MODS map: Metallic, Occlusion, Detail, and Smoothness
		[Toggle(_MASK_MAP)] _MaskMapToggle("Mask Map", Float) = 0
		[NoScaleOffset] _MaskMap("Mask (MODS)", 2D) = "white" {}
		_Metallic("Metallic", Range(0, 1)) = 0
		_Occlusion("Occlusion", Range(0, 1)) = 1
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_Fresnel("Fresnel", Range(0, 1)) = 1

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)
		
		[Space(8)]
		[HDR] _RimViewColor("Rim Light Color", Color) = (0.0, 0.0, 0.0, 1.0)
		_RimViewMask("Rim Mask", Range(0, 1)) = 0
		[HDR] _RimSunColor("Sun Rim Color", Color) = (0.0, 0.0, 0.0, 1.0)
		_RimSunPower("Sun Rim Power", Range(0.01, 100)) = 10
		_RimSunIntensity("Sum Rim Intensity", Range(0.0,100.0)) = 10

		[Space(16)]
		[Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha("Premultiply Alpha", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1

		// Unity's lightmapper hard-coded properties for transparency.
		[HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
		[HideInInspector] _Color("Base Color", Color) = (0.5, 0.5, 0.5, 1)
	}

	SubShader {
		HLSLINCLUDE
			#include "../../ShaderLibrary/Common.hlsl"
		ENDHLSL

		Pass {
			Name "CustomLit"
			Tags {
				"LightMode" = "CustomLit"
			}

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _CLIPPING
			#pragma shader_feature _PREMULTIPLY_ALPHA
			#pragma shader_feature _RECEIVE_SHADOWS
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _MASK_MAP

			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
			#pragma multi_compile _ _LIGHTS_PER_OBJECT
			
			#define _RIM_VIEW 1
			#define _RIM_SUN 1

			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment
			#include "ActorInput.hlsl"
			#include "../LitPass.hlsl"
			ENDHLSL
		}

		Pass {
			Name "ShadowCaster"
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_instancing

			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "ActorInput.hlsl"
			#include "../ShadowCasterPass.hlsl"
			ENDHLSL
		}

		Pass {
			Name "DepthOnly"
			Tags {
				"LightMode" = "DepthOnly"
			}

			ColorMask 0
			ZWrite On

			HLSLPROGRAM
			#pragma target 3.5
			#pragma multi_compile_instancing
			#pragma shader_feature _CLIPPING
			#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma vertex DepthOnlyPassVertex
			#pragma fragment DepthOnlyPassFragment
			#include "ActorInput.hlsl"
			#include "../DepthOnlyPass.hlsl"
			ENDHLSL
		}
	}

	CustomEditor "OpenCS.CustomShaderGUI"
}