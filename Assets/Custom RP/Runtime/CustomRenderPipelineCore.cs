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
        public Rect pixelRect;

        public bool isHdrEnabled;
        public bool postProcessEnabled;
        public bool requireDepthTexture;
        public bool requireOpaqueTexture;
        public int renderingLayerMask;

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

            UnityEngine.Profiling.Profiler.BeginSample("SupportsRenderTextureFormat");
            bool use32BitHDR = !needsAlpha && SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGB111110Float);
            UnityEngine.Profiling.Profiler.EndSample();
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

        public static void BlitProcedural(CommandBuffer buffer, RenderTargetIdentifier from, RenderTargetIdentifier to, Material material = null, int pass = 0)
        {
            buffer.SetGlobalTexture(bitTexId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            Material blitMat = material != null ? material : CustomRenderPipeline.asset.BlitMaterial;            
            buffer.DrawProcedural(Matrix4x4.identity, blitMat, pass, MeshTopology.Triangles, 3);
        }

        public static void FinalBlitProcedural(CommandBuffer buffer, RenderTargetIdentifier from, RenderTargetIdentifier to,
            Rect pixelRect, Material material = null, int pass = 0)
        {
            buffer.SetGlobalTexture(bitTexId, from);
            buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.SetViewport(pixelRect);
            Material blitMat = material != null ? material : CustomRenderPipeline.asset.BlitMaterial;
            buffer.DrawProcedural(Matrix4x4.identity, blitMat, pass, MeshTopology.Triangles, 3);
        }

        public static void ClearRenderTarget(CommandBuffer cmd, ClearFlag clearFlag, Color clearColor)
        {
            if (clearFlag != ClearFlag.None)
                cmd.ClearRenderTarget((clearFlag & ClearFlag.Depth) != 0, (clearFlag & ClearFlag.Color) != 0, clearColor);
        }

        public static void SetRenderTarget(CommandBuffer cmd,
            RenderTargetIdentifier colorBuffer, RenderBufferLoadAction colorLoadAction, RenderBufferStoreAction colorStoreAction,
            ClearFlag clearFlag, Color clearColor)
        {
            cmd.SetRenderTarget(colorBuffer, colorLoadAction, colorStoreAction);
            ClearRenderTarget(cmd, clearFlag, clearColor);
        }

        public static void SetRenderTarget(CommandBuffer cmd,
            RenderTargetIdentifier colorBuffer, RenderBufferLoadAction colorLoadAction, RenderBufferStoreAction colorStoreAction,
            RenderTargetIdentifier depthBuffer, RenderBufferLoadAction depthLoadAction, RenderBufferStoreAction depthStoreAction,
            ClearFlag clearFlag, Color clearColor)
        {
            cmd.SetRenderTarget(colorBuffer, colorLoadAction, colorStoreAction, depthBuffer, depthLoadAction, depthStoreAction);
            ClearRenderTarget(cmd, clearFlag, clearColor);
        }
    }
}