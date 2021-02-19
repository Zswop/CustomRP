#ifndef CUSTOM_LIT_PASS_INCLUDED
#define CUSTOM_LIT_PASS_INCLUDED

#include "LitPassCommon.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 baseUV : TEXCOORD0;

	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
	float4 positionCS : SV_POSITION;
	float4 baseUV : VAR_BASE_UV;

	float3 normalWS : VAR_NORMAL;
	float3 positionWS : VAR_POSITION;
#if defined(_NORMAL_MAP)
	float4 tangentWS : VAR_TANGENT;
#endif

	half3 fogFactor	: VAR_FOG_FACTOR;

	GI_VARYINGS_DATA		//TODO: vertexlight
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
    ZERO_INITIALIZE(InputData, inputData)

	inputData.positionWS = input.positionWS.xyz;

#if defined(_NORMAL_MAP)
	inputData.tangentWS = input.tangentWS.xyz;
	float sign = input.tangentWS.w;		// should be either +1 or -1
	float3 bitangentWS = cross(input.normalWS.xyz, input.tangentWS.xyz) * sign;
	inputData.normalWS = TransformTangentToWorld(normalTS,
		half3x3(input.tangentWS.xyz, bitangentWS.xyz, input.normalWS.xyz));
#else
	inputData.normalWS = normalize(input.normalWS);
#endif

    inputData.interpolatedNormalWS = input.normalWS.xyz;
	inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - input.positionWS.xyz);
	inputData.depthVS = -TransformWorldToView(input.positionWS.xyz).z;
	inputData.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

	inputData.fogCoord = input.fogFactor;
	inputData.lightmapUV = GI_FRAGMENT_DATA(input);
	inputData.bakedGI = SampleGI(inputData.lightmapUV, inputData.normalWS);
}

Varyings LitPassVertex(Attributes input) {
	Varyings output = (Varyings)0;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);

	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
#if defined(_NORMAL_MAP)
	float sign = input.tangentOS.w * GetOddNegativeScale();
	float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
	output.tangentWS = float4(tangentWS, sign);
#endif

	TRANSFER_GI_DATA(input, output);

	output.fogFactor = ComputeFogFactor(output.positionWS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

half4 LitPassFragment(Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	SurfaceData surfaceData;
	InitializeSurfaceData(input.baseUV, surfaceData);

	InputData inputData;
	InitializeInputData(input, surfaceData.normalTS, inputData);

	half3 color = CustomLighting(inputData, surfaceData);
	return OutputColor(color, inputData, surfaceData);
}

#endif