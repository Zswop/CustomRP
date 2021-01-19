#ifndef CUSTOM_UNLIT_META_PASS_INCLUDED
#define CUSTOM_UNLIT_META_PASS_INCLUDED

bool4 unity_MetaFragmentControl;
float unity_OneOverOutputBoost;
float unity_MaxOutputValue;

struct Attributes {
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
	float2 lightMapUV : TEXCOORD1;
};

struct Varyings {
	float4 positionCS : SV_POSITION;
	float4 baseUV : VAR_BASE_UV;
};

Varyings MetaPassVertex(Attributes input) {
	Varyings output;
	input.positionOS.xy = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
	input.positionOS.z = input.positionOS.z > 0.0 ? FLT_MIN : 0.0;

	output.positionCS = TransformWorldToHClip(input.positionOS);
	output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

half4 MetaPassFragment(Varyings input) : SV_TARGET {
	half4 base = GetBase(input.baseUV);

	half4 meta = 0.0;
	if (unity_MetaFragmentControl.x) {
		meta = half4(base.rgb, 1.0);
		meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
	}
	else if (unity_MetaFragmentControl.y) {
		meta = half4(base.rgb, 1.0);
	}
	return meta;
}
#endif