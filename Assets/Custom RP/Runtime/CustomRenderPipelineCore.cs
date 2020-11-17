//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public struct CameraData
    {
        public Camera camera;
        public RenderTexture targetTexture;
        public RenderTextureDescriptor cameraTargetDescriptor;
        public SortingCriteria defaultOpaqueSortFlags;

        public CameraType cameraType;
        public float renderScale;
        public float maxShadowDistance;

        public bool isHdrEnabled;
        public bool postProcessEnabled;
        public bool requireDepthTexture;
        public bool requireOpaqueTexture;

        public bool isSceneViewCamera { get { return cameraType == CameraType.SceneView; } }
        public bool isPreviewCamera { get { return cameraType == CameraType.Preview; } }
    }

    public struct RenderingData
    {
        public CameraData cameraData;
        public bool useDynamicBatching;
        public bool useGPUInstancing;
        public bool useLightsPerObject;
        public bool postProcessingEnabled;
        public PerObjectData perObjectData;
        public int colorLUTResolution;
        public ShadowSettings shadowSettings;
        public PostFXSettings postFXSettings;
    }

    public static class RenderingUtils
    {
        public static RenderTextureDescriptor CreateRenderTextureDescriptor(Camera camera, float renderScale,
            bool isHdrEnabled, int msaaSamples, bool needsAlpha)
        {
            RenderTextureDescriptor desc;
            RenderTextureFormat renderTextureFormatDefault = RenderTextureFormat.Default;
            desc = new RenderTextureDescriptor(camera.pixelWidth, camera.pixelHeight);
            desc.width = (int)((float)desc.width * renderScale);
            desc.height = (int)((float)desc.height * renderScale);

            bool use32BitHDR = !needsAlpha && SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGB111110Float);
            RenderTextureFormat hdrFormat = (use32BitHDR) ? RenderTextureFormat.RGB111110Float : RenderTextureFormat.DefaultHDR;
            if (camera.targetTexture != null)
            {
                desc.colorFormat = camera.targetTexture.descriptor.colorFormat;
                desc.depthBufferBits = camera.targetTexture.descriptor.depthBufferBits;
                desc.msaaSamples = camera.targetTexture.descriptor.msaaSamples;
                desc.sRGB = camera.targetTexture.descriptor.sRGB;
            }
            else
            {
                desc.colorFormat = isHdrEnabled ? hdrFormat : renderTextureFormatDefault;
                desc.depthBufferBits = 32;
                desc.msaaSamples = msaaSamples;
                desc.sRGB = (QualitySettings.activeColorSpace == ColorSpace.Linear);
            }

            desc.enableRandomWrite = false;
            desc.bindMS = false;
            desc.useDynamicScale = camera.allowDynamicResolution;
            return desc;
        }

        public static DrawingSettings CreateDrawingSettings(ShaderTagId shaderTagId, SortingCriteria sortingCriteria,
           ref RenderingData renderingData)
        {
            ref var cameraData = ref renderingData.cameraData;
            var camera = cameraData.camera;
            var sortingSettings = new SortingSettings(camera)
            {
                criteria = sortingCriteria
            };

            var drawingSettings = new DrawingSettings(shaderTagId, sortingSettings)
            {
                enableDynamicBatching = renderingData.useDynamicBatching,
                enableInstancing = renderingData.useGPUInstancing,
                perObjectData = renderingData.perObjectData,
            };

            return drawingSettings;
        }

        static int bitTexId = Shader.PropertyToID("_BlitTex");

        public static void BlitProcedural(CommandBuffer buffer, int from, int to, Material material = null, int pass = 0)
        {
            buffer.SetGlobalTexture(bitTexId, from);
            if (to != -1) { buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store); }
            else { buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget, RenderBufferLoadAction.DontCare, 
                RenderBufferStoreAction.Store); }

            if (material != null) { buffer.DrawProcedural(Matrix4x4.identity, material, pass, MeshTopology.Triangles, 3); }
            else { buffer.DrawProcedural(Matrix4x4.identity, CustomRenderPipeline.asset.BlitMaterial, 0, MeshTopology.Triangles, 3); }
        }
    }
}