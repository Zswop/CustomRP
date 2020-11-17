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
	float2 baseUV : VAR_BASE_UV;

#if defined(_NORMAL_MAP)
	float4 normalWS : VAR_NORMAL;	// xyz: normal, w: positionWS.x 
	float4 tangentWS : VAR_TANGENT; // xyz: tangent, w: positionWS.y
	float4 bitangentWS : VAR_BITANGENT; // xyz: bitangent, w: positionWS.z
#else
	float3 normalWS : VAR_NORMAL;
	float3 positionWS : VAR_POSITION;
#endif

	GI_VARYINGS_DATA		//TODO: combine vertexlight
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
    ZERO_INITIALIZE(InputData, inputData)

#if defined(_NORMAL_MAP)
	inputData.positionWS = float3(input.normalWS.w, input.tangentWS.w, input.bitangent.w);
	inputData.normalWS = TransformTangentToWorld(normalTS,
		half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
#else
	inputData.normalWS = normalize(input.normalWS);
	inputData.positionWS = input.positionWS;
#endif

    inputData.interpolatedNormalWS = input.normalWS.xyz;
	inputData.viewDirectionWS = normalize(_WorldSpaceCameraPos - input.positionWS.xyz);
	inputData.depthVS = -TransformWorldToView(input.positionWS.xyz).z;
	inputData.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

	inputData.lightmapUV = GI_FRAGMENT_DATA(input);
	inputData.bakedGI = SampleGI(inputData.lightmapUV, inputData.normalWS);
}

Varyings LitPassVertex(Attributes input) {
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	
	float3 positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(positionWS);

	float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
#if defined(_NORMAL_MAP)
	float sign = input.tangentOS.w * GetOddNegativeScale();
	float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
	float3 bitangentWS = cross(output.normalWS, output.tangentWS) * sign;
	output.normalWS = float4(normalWS, positionWS.x);
	output.tangentWS = float4(tangentWS, positionWS.y);
	output.bitangentWS = float4(bitangentWS, positionWS.z);
#else
	output.normalWS = normalWS;
	output.positionWS = positionWS;
#endif

	TRANSFER_GI_DATA(input, output);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

half4 LitPassFragment(Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	ClipLOD(input.positionCS.xy, unity_LODFade.x);
	
	half4 base = GetBase(input.baseUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	SurfaceData surfaceData;
	InitializeSurfaceData(input.baseUV, surfaceData);

	InputData inputData;
	InitializeInputData(input, surfaceData.normalTS, inputData);

	half3 color = CustomLighting(inputData, surfaceData);
	return half4(color, surfaceData.alpha);
}

#endif