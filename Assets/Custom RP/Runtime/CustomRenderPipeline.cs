//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public partial class CustomRenderPipeline : RenderPipeline
    {
        private bool support32BitHDR = true;
        private CameraRenderer renderer = new CameraRenderer();
        
        public static CustomRenderPipelineAsset asset
        {
            get => GraphicsSettings.currentRenderPipeline as CustomRenderPipelineAsset;
        }

        public CustomRenderPipeline(CustomRenderPipelineAsset asset)
        {
            GraphicsSettings.useScriptableRenderPipelineBatching = asset.useSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;

            // SYSTEMINFO APIS TAKE ENUM PARAMETER CREATE GC.ALLOC due to boxing
            support32BitHDR = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGB111110Float);
            Shader.globalRenderPipeline = "CustomPipeline";

            InitializeForEditor();
        }

        protected override void Dispose(bool disposing)
        {
            Shader.globalRenderPipeline = "";
            ReleaseForEditor();
            base.Dispose(disposing);
        }

        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            foreach (var camera in cameras)
            {
                BeginCameraRendering(context, camera);
                InitializeCameraData(camera, out var cameraData);
                RenderSingleCamera(context, ref cameraData);
                EndCameraRendering(context, camera);
            }
        }

        private void RenderSingleCamera(ScriptableRenderContext context, ref CameraData cameraData)
        {
            InitializeRenderingData(ref cameraData, out var renderingData);
            renderer.Render(context, ref renderingData);
        }

        private void InitializeCameraData(Camera camera, out CameraData cameraData)
        {
            cameraData = new CameraData();

            var settings = asset;
            cameraData.camera = camera;
            cameraData.cameraType = camera.cameraType;
            cameraData.targetTexture = camera.targetTexture;
            cameraData.isHdrEnabled = camera.allowHDR && settings.supportHDR;

            cameraData.requireOpaqueTexture = settings.requireOpaqueTexture;
            cameraData.requireDepthTexture = settings.requireDepthTexture;
            cameraData.renderScale = settings.renderScale;

            bool shadowEnabled = settings.supportShadows;
            float maxShadowDistance = Mathf.Min(settings.shadows.maxDistance, camera.farClipPlane);
            cameraData.maxShadowDistance = (shadowEnabled && maxShadowDistance >= camera.nearClipPlane) ? maxShadowDistance : 0.0f;

            var additinalCameraData = camera.gameObject.GetComponent<CustomAdditionalCameraData>();
            if (additinalCameraData != null)
            {
                cameraData.postProcessEnabled = additinalCameraData.postProcessing;
                cameraData.requireOpaqueTexture = additinalCameraData.requireOpaqueTexture;
                cameraData.requireDepthTexture = additinalCameraData.requireDepthTexture;
                cameraData.renderingLayerMask = additinalCameraData.renderingLayerMask;
                cameraData.maxShadowDistance = (additinalCameraData.renderShadows ?
                    cameraData.maxShadowDistance : 0.0f);
            }
            else
            {
                cameraData.postProcessEnabled = false;
                cameraData.requireOpaqueTexture = settings.requireOpaqueTexture;
                cameraData.requireOpaqueTexture = settings.requireDepthTexture;
                cameraData.renderingLayerMask = -1;
            }

            cameraData.postProcessEnabled &= SystemInfo.graphicsDeviceType != GraphicsDeviceType.OpenGLES2;
            cameraData.pixelRect = camera.pixelRect;

            int msaaSamples = 1;
            int msaaSettingSamples = (int)settings.MSAA;
            if (camera.allowMSAA && msaaSettingSamples > 1) {
                msaaSamples = camera.targetTexture != null ? camera.targetTexture.antiAliasing : msaaSettingSamples;
            }
            bool needsAlphaChannel = Graphics.preserveFramebufferAlpha || !support32BitHDR;
            cameraData.cameraTargetDescriptor = RenderingUtils.CreateRenderTextureDescriptor(camera, cameraData.renderScale, 
                cameraData.isHdrEnabled, msaaSamples, needsAlphaChannel);

            cameraData.SetViewAndProjectionMatrix(camera.worldToCameraMatrix, camera.projectionMatrix);
        }

        private void InitializeRenderingData(ref CameraData cameraData, out RenderingData renderingData)
        {
            renderingData = new RenderingData();
            renderingData.cameraData = cameraData;

            var settings = asset;
            renderingData.useDynamicBatching = settings.useDynamicBatching;
            renderingData.useGPUInstancing = settings.useGPUInstancing;
            renderingData.useLightsPerObject = settings.useLightsPerObject;
            renderingData.postProcessingEnabled = cameraData.postProcessEnabled;
            renderingData.shadowSettings = settings.shadows;
            renderingData.postFXSettings = settings.postFXSettings;
            renderingData.colorLUTResolution = (int)settings.colorLUTResolution;

            PerObjectData lightsPerObjectFlags = renderingData.useLightsPerObject ?
                PerObjectData.LightData | PerObjectData.LightIndices :
                PerObjectData.None;

            renderingData.perObjectData = PerObjectData.ReflectionProbes |
                    PerObjectData.LightProbe |
                    PerObjectData.Lightmaps |
                    PerObjectData.OcclusionProbe |
                    PerObjectData.ShadowMask |
                    lightsPerObjectFlags;
        }
    }
}