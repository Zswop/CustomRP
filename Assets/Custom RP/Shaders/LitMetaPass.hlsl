#ifndef CUSTOM_LIT_META_PASS_INCLUDED
#define CUSTOM_LIT_META_PASS_INCLUDED

#include "../ShaderLibrary/BRDF.hlsl"

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
	float2 baseUV : VAR_BASE_UV;
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
	SurfaceData surfaceData;
	InitializeSurfaceData(input.baseUV, surfaceData);
	BRDF brdf = GetBRDF(surfaceData.albedo, surfaceData.metallic,
		surfaceData.smoothness,	surfaceData.alpha
	);

	half4 meta = 0.0;
	if (unity_MetaFragmentControl.x) {
		meta = half4(brdf.diffuse, 1.0);
		meta.rgb += brdf.specular * brdf.roughness * 0.5;
		meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
	}
	else if (unity_MetaFragmentControl.y) {
		meta = half4(surfaceData.emission, 1.0);
	}
	return meta;
}
#endif