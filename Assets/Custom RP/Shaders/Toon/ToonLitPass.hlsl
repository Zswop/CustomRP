#ifndef CUSTOM_TOON_LIT_PASS_INCLUDED
#define CUSTOM_TOON_LIT_PASS_INCLUDED

//#include "../../ShaderLibrary/Surface.hlsl"
//#include "../../ShaderLibrary/Shadows.hlsl"
//#include "../../ShaderLibrary/Light.hlsl"
//#include "ToonLighting.hlsl"

struct Attributes{
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float2 baseUV : TEXCOORD0;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings{
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
	float2 baseUV : VAR_BASE_UV;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings ToonLitPassVertex(Attributes input) {
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

float4 ToonLitPassFragment(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);
	half4 base = GetBase(input.baseUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif
	return base;

	//float4 rimColor = GetRimColor(input.baseUV);
	//float rimStrength = GetRimStrength(input.baseUV).r;
	//float3 color = GetLighting(surface, gi,	rimColor.rgb, rimColor.a, rimStrength);
	//return float4(color, surface.alpha);
}

#endif