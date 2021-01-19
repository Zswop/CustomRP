#ifndef CUSTOM_INDIRECT_LINGHTING_INCLUDED
#define CUSTOM_INDIRECT_LINGHTING_INCLUDED

half3 IndirectLighting(InputData inputData, SurfaceData surfaceData, BRDF brdf)
{
	float3 normal = inputData.normalWS;
	float3 viewDir = inputData.viewDirectionWS;
	
	half fresnel = surfaceData.fresnel;
	half occlusion = surfaceData.occlusion;

	half3 bakedGI = inputData.bakedGI;
	half3 indirectSpec = SampleEnvironment(viewDir, normal, brdf.perceptualRoughness);
	half3 color = GetBRDFIndirect(brdf, bakedGI, indirectSpec, normal, viewDir, fresnel) * occlusion;
	return color;
}

#endif