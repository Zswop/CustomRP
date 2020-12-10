//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public partial class CameraRenderer
    {
        const string bufferName = "Render Camera";

        static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
        static ShaderTagId litShaderTagId = new ShaderTagId("CustomLit");

        static int cameraColorAttachmentId = Shader.PropertyToID("_CameraColorTexture");
        static int cameraDepthAttachmentId = Shader.PropertyToID("_CameraDepthAttachment");

        static int cameraOpaqueTextureId = Shader.PropertyToID("_CameraOpaqueTexture");
        static int cameraDepthTextureId = Shader.PropertyToID("_CameraDepthTexture");

        static int colorGradingLUTId = Shader.PropertyToID("_ColorGradingLUT");

        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        ScriptableRenderContext context;
        CullingResults cullingResults;
        Camera camera;

        Lighting lighting = new Lighting();
        PostFXStack postFXStack = new PostFXStack();
        DepthPrepare depthPrepare = new DepthPrepare();
        ColorGradingLut colorGradingLut = new ColorGradingLut();

        bool createColorTexture = false;
        bool createDepthTexture = false;

        bool requireDepthOnlyPass = false;
        bool requireColorGradingLut = false;
        bool copyOpaqueColor = false;

        public void Render(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            this.context = context;

            ref var cameraData = ref renderingData.cameraData;
            this.camera = cameraData.camera;

            PrepareBuffer();
            PrepareForSceneWindow();
            if (!Cull(cameraData.maxShadowDistance))
            {
                return;
            }

            buffer.BeginSample(SampleName);
            ExecuteBuffer();
            lighting.Setup(context, ref cullingResults, ref renderingData);
            postFXStack.Setup(ref cameraData, renderingData.postFXSettings,
                renderingData.colorLUTResolution);

            SetupDepthPrepare(context, ref cullingResults, ref renderingData);
            SetupColorGradingLut(context, ref renderingData);
            buffer.EndSample(SampleName);

            Setup(ref renderingData);
            DrawVisibleGeometry(ref renderingData);
            DrawUnsupportedShaders();
            DrawGizmosBeforeFX();
            if (postFXStack.IsActive){
                postFXStack.Render(context, cameraColorAttachmentId);
            }
            DrawGizmosAfterFX();
            Cleanup();
            Submit();
        }

        bool Cull(float maxShadowDistance)
        {
            if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
            {
                bool isShadowDistanceZero = Mathf.Approximately(maxShadowDistance, 0.0f);
                if (isShadowDistanceZero) { p.cullingOptions &= ~CullingOptions.ShadowCasters; }
                p.shadowDistance = maxShadowDistance;
                cullingResults = context.Cull(ref p);
                return true;
            }
            return false;
        }

        void SetupDepthPrepare(ScriptableRenderContext context, ref CullingResults cullingResults,
            ref RenderingData renderingData)
        {
            ref var cameraData = ref renderingData.cameraData;
            int msaaSamples = cameraData.cameraTargetDescriptor.msaaSamples;
            var requiresDepthTexture = cameraData.requireDepthTexture;
            requireDepthOnlyPass = requiresDepthTexture && msaaSamples > 1;
            // - Scene or preview cameras always require camera target depth.
            // We do a depth pre-pass to simplify it and it shouldn't matter much for editor.
            requireDepthOnlyPass |= cameraData.isSceneViewCamera;
            requireDepthOnlyPass |= cameraData.isPreviewCamera;
            if (requireDepthOnlyPass) {
                depthPrepare.Setup(context, ref cullingResults, ref renderingData, cameraDepthTextureId);
            }
        }

        void SetupColorGradingLut(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            requireColorGradingLut = postFXStack.IsActive;
            if (requireColorGradingLut)
            {
                colorGradingLut.Setup(renderingData.postFXSettings, renderingData.colorLUTResolution, colorGradingLUTId);
                colorGradingLut.Render(context);
            }
        }

        void Setup(ref RenderingData renderingData)
        {
            ref var cameraData = ref renderingData.cameraData;
            context.SetupCameraProperties(camera);
            
            createColorTexture = cameraData.requireOpaqueTexture;
            createColorTexture |= cameraData.renderScale != 1.0f;
            createColorTexture |= postFXStack.IsActive;

            var requiresDepthTexture = cameraData.requireDepthTexture;
            createDepthTexture = requiresDepthTexture && !requireDepthOnlyPass;
            createColorTexture |= createDepthTexture;

            copyOpaqueColor = cameraData.requireOpaqueTexture;

            CreateCameraRenderTarget(ref cameraData);

            ClearFlag clearFlag = GetCameraClearFlag(camera.clearFlags);
            if (postFXStack.IsActive) { clearFlag = ClearFlag.All; }
            Color clearColor = (clearFlag & ClearFlag.Color) != 0 ? 
                camera.backgroundColor.linear : Color.clear;
            SetRenderTarget(clearFlag, clearColor);

            buffer.BeginSample(SampleName);
            ExecuteBuffer();
        }

        void Cleanup()
        {
            lighting.Cleanup();
            if (requireDepthOnlyPass) { depthPrepare.Cleanup(); }
            if (requireColorGradingLut) { colorGradingLut.Clearup(); }

            if (copyOpaqueColor) { buffer.ReleaseTemporaryRT(cameraOpaqueTextureId); }
            if (createDepthTexture) { buffer.ReleaseTemporaryRT(cameraDepthTextureId); }

            if (createColorTexture) { buffer.ReleaseTemporaryRT(cameraColorAttachmentId); }
            if (createDepthTexture) { buffer.ReleaseTemporaryRT(cameraDepthAttachmentId); }

            requireDepthOnlyPass = false;
            requireColorGradingLut = false;

            copyOpaqueColor = false;
            createColorTexture = false;
            createDepthTexture = false;
        }

        void Submit()
        {
            buffer.EndSample(SampleName);
            ExecuteBuffer();
            context.Submit();
        }

        void ExecuteBuffer()
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }
       
        void DrawVisibleGeometry(ref RenderingData renderingDta)
        {
            ref CameraData cameraData = ref renderingDta.cameraData;
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque,
                renderingLayerMask : (uint)cameraData.renderingLayerMask
            );
            DrawingSettings drawingSettings = RenderingUtils.CreateDrawingSettings(unlitShaderTagId,
                SortingCriteria.CommonOpaque, ref renderingDta);
            drawingSettings.SetShaderPassName(1, litShaderTagId);
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

            context.DrawSkybox(camera);
            CopyColorAndDepth(ref cameraData);
          
            var sortingSettings = drawingSettings.sortingSettings;
            sortingSettings.criteria = SortingCriteria.CommonTransparent;
            drawingSettings.sortingSettings = sortingSettings;
            filteringSettings.renderQueueRange = RenderQueueRange.transparent;
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
            
            bool cameraTargetResolved = postFXStack.IsActive || !createColorTexture;
            if (!cameraTargetResolved) {
                RenderTargetIdentifier cameraTarget = (cameraData.targetTexture != null) ? 
                    new RenderTargetIdentifier(cameraData.targetTexture) : BuiltinRenderTextureType.CameraTarget;
                RenderingUtils.FinalBlitProcedural(buffer, cameraColorAttachmentId, cameraTarget, cameraData.pixelRect);
            }
        }

        void CopyColorAndDepth(ref CameraData cameraData)
        {
            // TODO: Use Command.CopyTexture, which is much more effcient than doing it via a full-screen draw call.

            if (copyOpaqueColor || createDepthTexture)
            {
                buffer.EndSample(SampleName);
                ExecuteBuffer();
            }

            if (copyOpaqueColor)
            {
                buffer.GetTemporaryRT(cameraOpaqueTextureId, cameraData.cameraTargetDescriptor);
                RenderingUtils.BlitProcedural(buffer, cameraColorAttachmentId, cameraOpaqueTextureId, null, 0);
                ExecuteBuffer();
            }

            if (createDepthTexture)
            {
                //TODO: SV_DEPTH
                buffer.GetTemporaryRT(cameraDepthTextureId, cameraData.cameraTargetDescriptor);
                RenderingUtils.BlitProcedural(buffer, cameraDepthAttachmentId, cameraDepthTextureId, null, 0);
                ExecuteBuffer();
            }

            if (copyOpaqueColor || createDepthTexture)
            {
                SetRenderTarget(ClearFlag.None, Color.clear);
                buffer.BeginSample(SampleName);
                ExecuteBuffer();
            }
        }

        void CreateCameraRenderTarget(ref CameraData cameraData)
        {
            if (createColorTexture)
            {
                var colorDescriptor = cameraData.cameraTargetDescriptor;
                colorDescriptor.depthBufferBits = createDepthTexture ? 0 : 32;
                buffer.GetTemporaryRT(cameraColorAttachmentId, colorDescriptor, FilterMode.Bilinear);
            }

            if (createDepthTexture)
            {
                var depthDescriptor = cameraData.cameraTargetDescriptor;
                depthDescriptor.colorFormat = RenderTextureFormat.Depth;
                depthDescriptor.depthBufferBits = 32;
                depthDescriptor.msaaSamples = 1;
                buffer.GetTemporaryRT(cameraDepthAttachmentId, depthDescriptor, FilterMode.Point);
            }
        }

        void SetRenderTarget(ClearFlag clearFlag, Color clearColor)
        {
            RenderTargetIdentifier colorAttachment = createColorTexture ?
                (RenderTargetIdentifier)cameraColorAttachmentId : BuiltinRenderTextureType.CameraTarget;

            RenderTargetIdentifier depthAttachment = createDepthTexture ?
                (RenderTargetIdentifier)cameraDepthAttachmentId : BuiltinRenderTextureType.CameraTarget;

            SetRenderTarget(buffer, colorAttachment, depthAttachment, clearFlag, clearColor);
        }

        internal static ClearFlag GetCameraClearFlag(CameraClearFlags cameraClearFlags)
        {
#if UNITY_EDITOR
            // For now, to fix FrameDebugger in Editor, force a clear.
            cameraClearFlags = CameraClearFlags.Color;
#endif
            // Always clear on first render pass in mobile as it's same perf of DontCare and avoid tile clearing issues.
            if (Application.isMobilePlatform)
                return ClearFlag.All;

            if ((cameraClearFlags == CameraClearFlags.Skybox && RenderSettings.skybox != null) ||
                cameraClearFlags == CameraClearFlags.Nothing)
                return ClearFlag.Depth;

            return ClearFlag.All;
        }

        internal static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier colorAttachment, 
            RenderTargetIdentifier depthAttachment, ClearFlag clearFlag, Color clearColor)
        {
            RenderBufferLoadAction colorLoadAction = ((uint)clearFlag & (uint)ClearFlag.Color) != 0 ?
                RenderBufferLoadAction.DontCare : RenderBufferLoadAction.Load;

            RenderBufferLoadAction depthLoadAction = ((uint)clearFlag & (uint)ClearFlag.Depth) != 0 ?
                RenderBufferLoadAction.DontCare : RenderBufferLoadAction.Load;

            SetRenderTarget(cmd, colorAttachment, colorLoadAction, RenderBufferStoreAction.Store,
                depthAttachment, depthLoadAction, RenderBufferStoreAction.Store, clearFlag, clearColor);
        }

        static void SetRenderTarget(CommandBuffer cmd,
            RenderTargetIdentifier colorAttachment, RenderBufferLoadAction colorLoadAction, RenderBufferStoreAction colorStoreAction,
            RenderTargetIdentifier depthAttachment, RenderBufferLoadAction depthLoadAction, RenderBufferStoreAction depthStoreAction,
            ClearFlag clearFlag, Color clearColor)
        {
            if (depthAttachment == BuiltinRenderTextureType.CameraTarget)
            {
                RenderingUtils.SetRenderTarget(cmd, colorAttachment, colorLoadAction, colorStoreAction, clearFlag, clearColor);
            }
            else
            {
                RenderingUtils.SetRenderTarget(cmd, colorAttachment, colorLoadAction, colorStoreAction,
                        depthAttachment, depthLoadAction, depthStoreAction, clearFlag, clearColor);
            }
        }
    }
}