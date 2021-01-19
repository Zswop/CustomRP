#ifndef CUSTOM_DEPTH_ONLY_PASS_INCLUDED
#define CUSTOM_DEPTH_ONLY_PASS_INCLUDED

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
	float4 positionCS : SV_POSITION;
	float4 baseUV : VAR_BASE_UV;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings DepthOnlyPassVertex(Attributes input) {
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	output.positionCS = TransformObjectToHClip(input.positionOS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

half4 DepthOnlyPassFragment(Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);	
	ClipLOD(input.positionCS.xy, unity_LODFade.x);

	half4 base = GetBase(input.baseUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif
	return 0;
}

#endif