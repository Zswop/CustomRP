#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED

struct Attributes 
{
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings 
{
	float4 positionCS : SV_POSITION;
	float4 baseUV : VAR_BASE_UV;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings UnlitPassVertex(Attributes input)
{
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	output.positionCS = TransformObjectToHClip(input.positionOS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

half4 UnlitPassFragment(Varyings input) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);

	half4 base = GetBase(input.baseUV);
#if defined(_CLIPPING)
	clip(base.a - GetCutoff(input.baseUV));
#endif
	return base;
}

#endif