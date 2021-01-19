//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

namespace OpenCS
{
    public class Lighting
    {
        const string bufferName = "Lighting";

        const int maxDirLightCount = 4;

        static int
            dirLightCountId = Shader.PropertyToID("_DirectionalLightCount"),
            dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors"),
            dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections"),
            dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");

        static Vector4[]
            dirLightColors = new Vector4[maxDirLightCount],
            dirLightDirections = new Vector4[maxDirLightCount],
            dirLightShadowData = new Vector4[maxDirLightCount];
        
        const int maxOtherLightCount = 64;

        static int
            otherLightCountId = Shader.PropertyToID("_OtherLightCount"),
            otherLightColorsId = Shader.PropertyToID("_OtherLightColors"),
            otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions"),
            otherLightDirectionsId = Shader.PropertyToID("_OtherLightDirections"),
            otherLightSpotAnglesId = Shader.PropertyToID("_OtherLightSpotAngles"),
            otherLightShadowDataId = Shader.PropertyToID("_OtherLightShadowData");

        static Vector4[]
            otherLightColors = new Vector4[maxOtherLightCount],
            otherLightPositions = new Vector4[maxOtherLightCount],
            otherLightDirections = new Vector4[maxOtherLightCount],
            otherLightSpotAngles = new Vector4[maxOtherLightCount],
            otherLightShadowData = new Vector4[maxOtherLightCount];

        static string lightsPerObjectKeyword = "_LIGHTS_PER_OBJECT";

        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        CullingResults cullingResults;

        Shadows shadows = new Shadows();

        public void Setup(ScriptableRenderContext context, ref CullingResults cullingResults,
            ref RenderingData renderingData)
        {
            this.cullingResults = cullingResults;
            buffer.BeginSample(bufferName);

            shadows.Setup(context, cullingResults, renderingData.shadowSettings);
            SetupLights(renderingData.useLightsPerObject);
            shadows.Render();

            buffer.EndSample(bufferName);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        public void Cleanup()
        {
            shadows.Cleanup();
        }
        
        int GetMainLightIndex(NativeArray<VisibleLight> visibleLights)
        {
            int totalVisibleLights = visibleLights.Length;

            if (totalVisibleLights == 0)
                return -1;
            
            int brightestDirectionalLightIndex = -1;
            float brightestLightIntensity = 0.0f;
            for (int i = 0; i < totalVisibleLights; ++i)
            {
                VisibleLight currVisibleLight = visibleLights[i];
                Light currLight = currVisibleLight.light;

                if (currLight == null)
                    break;

                // In case no shadow light is present we will return the brightest directional light
                if (currVisibleLight.lightType == LightType.Directional &&
                        currLight.intensity > brightestLightIntensity)
                {
                    brightestLightIntensity = currLight.intensity;
                    brightestDirectionalLightIndex = i;
                }
            }

            return brightestDirectionalLightIndex;
        }

        void SetupLights(bool useLightsPerObject)
        {
            NativeArray<int> indexMap = useLightsPerObject ? 
                cullingResults.GetLightIndexMap(Allocator.Temp) : default;
            NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;

            int i = 0;
            int dirLightCount = 0, otherLightCount = 0;
            int mainLightIndex = GetMainLightIndex(visibleLights);
            if (mainLightIndex != -1)
            {
                VisibleLight visibleLight = visibleLights[mainLightIndex];
                SetupDirectionalLight(dirLightCount++, i, ref visibleLight);
            }
            for (i = 0; i < visibleLights.Length; i++)
            {
                int newIndex = -1;

                if (i != mainLightIndex)
                {
                    VisibleLight visibleLight = visibleLights[i];
                    switch (visibleLight.lightType)
                    {
                        case LightType.Directional:
                            if (dirLightCount < maxDirLightCount)
                            {
                                SetupDirectionalLight(dirLightCount++, i, ref visibleLight);
                            }
                            break;
                        case LightType.Point:
                            if (otherLightCount < maxOtherLightCount)
                            {
                                newIndex = otherLightCount;
                                SetupPointLight(otherLightCount++, i, ref visibleLight);
                            }
                            break;
                        case LightType.Spot:
                            if (otherLightCount < maxOtherLightCount)
                            {
                                newIndex = otherLightCount;
                                SetupSpotLight(otherLightCount++, i, ref visibleLight);
                            }
                            break;
                        default: break;
                    }
                }

                if (useLightsPerObject)
                { 
                    indexMap[i] = newIndex; 
                }
            }

            if (useLightsPerObject)
            {
                for (; i < indexMap.Length; ++i) 
                { 
                    indexMap[i] = -1;
                }
                cullingResults.SetLightIndexMap(indexMap);
                indexMap.Dispose();
            }

            if (useLightsPerObject) { Shader.EnableKeyword(lightsPerObjectKeyword); }
            else { Shader.DisableKeyword(lightsPerObjectKeyword); }

            // Main Light is always a directional light, put in slot 0.
            if (dirLightCount > 0)
            {
                buffer.SetGlobalInt(dirLightCountId, dirLightCount);
                buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
                buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
                buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
            }
            else
            {
                dirLightColors[0] = Color.black;
                dirLightDirections[0] = new Vector4(0, 0, 1, 0);
                dirLightShadowData[0] = new Vector4(0, 0, 0, -1);
                buffer.SetGlobalInt(dirLightCountId, 1);
                buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
                buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
                buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
            }

            buffer.SetGlobalInt(otherLightCountId, otherLightCount);
            if (otherLightCount > 0)
            {
                buffer.SetGlobalVectorArray(otherLightColorsId, otherLightColors);
                buffer.SetGlobalVectorArray(otherLightPositionsId, otherLightPositions);
                buffer.SetGlobalVectorArray(otherLightDirectionsId, otherLightDirections);
                buffer.SetGlobalVectorArray(otherLightSpotAnglesId, otherLightSpotAngles);
                buffer.SetGlobalVectorArray(otherLightShadowDataId, otherLightShadowData);
            }
        }

        void SetupDirectionalLight(int index, int visibleIndex, ref VisibleLight visibleLight)
        {
            dirLightColors[index] = visibleLight.finalColor;
            dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
            dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, visibleIndex);
        }

        void SetupPointLight(int index, int visibleIndex, ref VisibleLight visibleLight)
        {
            otherLightColors[index] = visibleLight.finalColor;
            Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
            position.w = 1.0f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
            otherLightPositions[index] = position;
            otherLightSpotAngles[index] = new Vector4(0f, 1f);
            otherLightShadowData[index] = shadows.ReserveOtherShadows(visibleLight.light, visibleIndex);
        }

        void SetupSpotLight(int index, int visibleIndex, ref VisibleLight visibleLight)
        {
            otherLightColors[index] = visibleLight.finalColor;
            Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
            position.w = 1.0f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
            otherLightPositions[index] = position;
            otherLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);

            Light light = visibleLight.light;
            float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.innerSpotAngle);
            float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * visibleLight.spotAngle);
            float angleRangeInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
            otherLightSpotAngles[index] = new Vector4(angleRangeInv, -outerCos * angleRangeInv);
            otherLightShadowData[index] = shadows.ReserveOtherShadows(light, visibleIndex);
        }
    }
}