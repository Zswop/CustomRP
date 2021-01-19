#ifndef CUSTOM_PARTICLES_UNLIT_PASS_INCLUDED
#define CUSTOM_PARTICLES_UNLIT_PASS_INCLUDED

#include "../../ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "../../ShaderLibrary/DeclareDepthTexture.hlsl"

struct Attributes 
{
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	half4 color : COLOR;
	float2 texcoord : TEXCOORD0;
	float4 tangentOS : TANGENT;	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings 
{
#if defined(_VERTEX_COLORS)
	half4 color : COLOR;
#endif
	float2 texcoord : TEXCOORD0;
	float3 positionWS : TEXCOORD1;
	float3 normalWS : TEXCOORD2;

#if defined(_DISTORTION) || defined(_SOFT_PARTICLES) || defined(_NEAR_FADE)
	float4 screenPos : TEXCOORD3;
#endif

	float4 positionCS : SV_POSITION;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) 
{
    ZERO_INITIALIZE(InputData, inputData)

	inputData.normalWS = normalize(input.normalWS);
	inputData.positionWS = input.positionWS;

	inputData.interpolatedNormalWS = input.normalWS.xyz;
	inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - input.positionWS.xyz);
}

Varyings ParticleUnlitVertex(Attributes input)
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

#if defined(_VERTEX_COLORS)
	output.color = input.color;
#endif

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.texcoord = input.texcoord;

#if defined(_DISTORTION) || defined(_SOFT_PARTICLES) || defined(_NEAR_FADE)
	output.screenPos = ComputeScreenPos(output.positionCS);
#endif
	return output;
}

half3 DistortionScene(half4 base, float3 screenPos, float2 uvOffset, half blend)
{
	float2 screenUV = screenPos.xy + uvOffset * base.a;
	half3 sceneColor = SampleCameraOpaqueColor(screenUV).rgb;
	return lerp(sceneColor, base.rgb, saturate(base.a - blend));
}

half4 ParticleUnlitFragment(Varyings input) : SV_Target
{
	float2 uvOffset = 0;
#if defined(DISTORTION_UV_OFFSET)
	uvOffset = DISTORTION_UV_OFFSET(input.texcoord);
#endif

	half4 color = SampleBase(input.texcoord, uvOffset);
#if defined(_VERTEX_COLORS)
	color *= input.color;
#endif

    float3 screenPos = float3(0,0,0);
#if defined(_DISTORTION) || defined(_SOFT_PARTICLES) || defined(_NEAR_FADE)
    screenPos = input.screenPos.xyz / input.screenPos.w;
#endif

#if defined(_NEAR_FADE)
	float curDepth = LinearEyeDepth(screenPos.z, _ZBufferParams);
	float nearAttenuation = (curDepth - _NearFadeDistance) / _NearFadeRange;
	color.a *= saturate(nearAttenuation);
#endif

#if defined(_SOFT_PARTICLES)
	float sceneDepth = LinearEyeDepth(SampleCameraDepth(screenPos.xy), _ZBufferParams);
	float thisDepth = LinearEyeDepth(screenPos.z, _ZBufferParams);
	float depthDelta = sceneDepth - thisDepth;
	float softAttenuation = (depthDelta - _SoftParticlesDistance) / _SoftParticlesRange;
	color.a *= saturate(softAttenuation);
#endif

#if defined(_DISTORTION) && defined(_DISTORTION_SCENE)
	color.rgb = DistortionScene(color, screenPos, uvOffset, _DistortionBlend);
#endif

#if defined(_ALPHA_MASK)
	color.r *= AlphaMask(input.texcoord, uvOffset);
#endif

	return color;
}

#endif