#ifndef CUSTOM_WATER_COMMON_PASS_INCLUDED
#define CUSTOM_WATER_COMMON_PASS_INCLUDED

#include "../LitPassCommon.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 baseUV : TEXCOORD0;
};

struct Varyings {
	float4 positionCS : SV_POSITION;

	float2 baseUV : VAR_BASE_UV;

	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
#if defined(_NORMAL_MAP)
	float3 tangentWS : VAR_TANGENT;
	float3 bitangentWS : VAR_BITANGENT;
#endif
	float4 screenPos : VAR_SCREEN_POS;
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
    ZERO_INITIALIZE(InputData, inputData)

	inputData.positionWS = input.positionWS;
#if defined(_NORMAL_MAP)
	inputData.normalWS = TransformTangentToWorld(normalTS,
		half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
#else
	inputData.normalWS = normalize(input.normalWS);
#endif
	
    inputData.interpolatedNormalWS = input.normalWS;
	inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - input.positionWS);
	inputData.depthVS = -TransformWorldToView(input.positionWS).z;
	inputData.dither = InterleavedGradientNoise(input.positionCS.xy, 0);
	inputData.screenPos = input.screenPos;
}

Varyings WaterPassVertex(Attributes input) {
	Varyings output;

#if defined(_GERSTNER_WAVE)
	WaveData waveData;
	InitializeWaterWaveData(input.positionOS, waveData);
	output.positionWS = TransformObjectToWorld(waveData.position);
	output.positionCS = TransformWorldToHClip(output.positionWS);	
	
	float3 normalOS = normalize(cross(waveData.bitangent, waveData.tangent));
	output.normalWS = TransformObjectToWorldNormal(normalOS);
	#if defined(_NORMAL_MAP)
		float sign = input.tangentOS.w * GetOddNegativeScale();
		output.tangentWS = TransformObjectToWorldDir(waveData.tangent);
		output.bitangentWS = cross(output.normalWS, output.tangentWS) * sign;
	#endif
#else
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	#if defined(_NORMAL_MAP)
		float sign = input.tangentOS.w * GetOddNegativeScale();
		output.tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
		output.bitangentWS = cross(output.normalWS, output.tangentWS) * sign;
	#endif
#endif

	output.screenPos = ComputeScreenPos(output.positionCS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

float BackgroundLinearEyeDepth(float2 uv) {
	float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
	float backgroundDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
	return backgroundDepth;
}

float3 ColorBelowWater(float4 screenPos, float3 normalTS) {
	float2 uvOffset = normalTS.xy * _RefractionStrength;
	float2 uv = (screenPos.xy + uvOffset) / screenPos.w;
	float backgroundDepth = BackgroundLinearEyeDepth(uv);
	//return pow(sin(3.14 * backgroundDepth), 2.0);
	
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	float depthDifference = backgroundDepth - surfaceDepth;
	//return depthDifference / 20;

	uvOffset *= saturate(depthDifference);
	uv = (screenPos.xy + uvOffset) / screenPos.w;
	backgroundDepth = BackgroundLinearEyeDepth(uv);
	depthDifference = backgroundDepth - surfaceDepth;
	float3 backgroundColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv).rgb;
	float fogFactor = exp2(-_WaterFogDensity * depthDifference);
	return lerp(_WaterFogColor, backgroundColor, fogFactor);
}

half4 WaterPassFragment(Varyings input) : SV_TARGET {
	SurfaceData surfaceData;
	InitializeWaterSurfaceData(input.baseUV, surfaceData);

	InputData inputData;
	InitializeInputData(input, surfaceData.normalTS, inputData);

	float3 colorBelow = ColorBelowWater(inputData.screenPos, surfaceData.normalTS);
	surfaceData.emission = colorBelow * (1 - surfaceData.alpha);

	half3 color = CustomLighting(inputData, surfaceData);
	return half4(color, surfaceData.alpha);
}

#endif