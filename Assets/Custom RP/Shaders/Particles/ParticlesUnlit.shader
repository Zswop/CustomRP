Shader "OpenCS/CustomRP/Particles/Unlit"
{
	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		[Toggle(_VERTEX_COLORS)] _VertexColors ("Vertex Colors", Float) = 0
		_FlowDirection("Flow Direction", Vector) = (0.0, 0.0, 0.0, 0.0)

		[Space(2)][Header(Near Fade)]
		[Toggle(_NEAR_FADE)] _NearFade ("Near Fade", Float) = 0
		_NearFadeDistance ("Near Fade Distance", Range(0.0, 10.0)) = 0
		_NearFadeRange ("Near Fade Range", Range(0.01, 10.0)) = 1
		
		[Space(2)][Header(Soft Particle)]
		[Toggle(_SOFT_PARTICLES)] _SoftParticles ("Soft Particles", Float) = 0
		_SoftParticlesDistance ("Soft Particles Distance", Range(0.0, 10.0)) = 0
		_SoftParticlesRange ("Soft Particles Range", Range(0.01, 10.0)) = 1

		[Space(2)][Header(Distortion)]
		[Toggle(_DISTORTION)] _DistortionToggle("Distortion", Float) = 0
		[NoScaleOffset]_DistortionMap("Distortion Map", 2D) = "white"{}
		_DistortionDirection("Distortion (X:xy, Y:zw)", Vector) = (0.0, 0.0, 0.0, 0.0)
		_DistortionStrength("Distortion Strength", Range(0, 1)) = 1.0
		_DistortionBlend("Distortion Blend", Float) = 0.5
		[MaterialToggle]_DistortionBase("Distortion Main", float) = 0

		[HideInInspector] _SrcBlend("Src Blend", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
	}

	SubShader
	{
		HLSLINCLUDE
		#include "../../ShaderLibrary/Common.hlsl"
		ENDHLSL

		Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline" = "CustomPipeline" }

		Pass
		{
			Blend[_SrcBlend][_DstBlend]
			Cull[_Cull]
			ZWrite Off
		
			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _VERTEX_COLORS
			#pragma shader_feature _NEAR_FADE
			#pragma shader_feature _SOFT_PARTICLES
			#pragma shader_feature _DISTORTION

			#pragma vertex ParticleUnlitVertex
			#pragma fragment ParticleUnlitFragment
			#include "ParticlesUnlitInput.hlsl"
			#include "ParticlesUnlitPass.hlsl"
			ENDHLSL
		}
	}
}