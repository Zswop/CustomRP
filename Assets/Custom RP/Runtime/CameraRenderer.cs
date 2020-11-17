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

        public void Render(ScriptableRenderContext context, ref RenderingData renderingDta)
        {
            this.context = context;

            ref var cameraData = ref renderingDta.cameraData;
            this.camera = cameraData.camera;

            PrepareBuffer();
            PrepareForSceneWindow();
            if (!Cull(cameraData.maxShadowDistance))
            {
                return;
            }

            buffer.BeginSample(SampleName);
            ExecuteBuffer();
            lighting.Setup(context, ref cullingResults, ref renderingDta);
            postFXStack.Setup(context, ref cameraData, renderingDta.postFXSettings, 
                renderingDta.colorLUTResolution);

            SetupDepthPrepare(context, ref cullingResults, ref renderingDta);
            SetupColorGradingLut(context, ref renderingDta);
            buffer.EndSample(SampleName);

            Setup(ref renderingDta);
            DrawVisibleGeometry(ref renderingDta);
            DrawUnsupportedShaders();
            DrawGizmosBeforeFX();
            if (postFXStack.IsActive){
                postFXStack.Render(cameraColorAttachmentId, cameraDepthAttachmentId);
            }
            DrawGizmosAfterFX();
            Cleanup();
            Submit();
        }

        bool Cull(float maxShadowDistance)
        {
            if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
            {
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
            context.SetupCameraProperties(camera);
            CameraClearFlags flags = camera.clearFlags;

            ref var cameraData = ref renderingData.cameraData;
            copyOpaqueColor = cameraData.requireOpaqueTexture;

            createColorTexture = cameraData.requireOpaqueTexture;
            createColorTexture |= cameraData.renderScale != 1.0f;
            createColorTexture |= postFXStack.IsActive;

            var requiresDepthTexture = cameraData.requireDepthTexture;
            createDepthTexture = requiresDepthTexture && !requireDepthOnlyPass;
            createColorTexture |= createDepthTexture;

            CreateCameraRenderTarget(ref cameraData);
            SetRenderTarget();

            if (postFXStack.IsActive){
                if (flags > CameraClearFlags.Color) { flags = CameraClearFlags.Color; }
            }

            buffer.ClearRenderTarget(
                flags <= CameraClearFlags.Depth,
                flags == CameraClearFlags.Color,
                flags == CameraClearFlags.Color ?
                    camera.backgroundColor.linear : Color.clear
            );
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

        void SetRenderTarget()
        {
            if (createColorTexture)
            {
                if (createDepthTexture)
                {
                    buffer.SetRenderTarget(cameraColorAttachmentId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
                        cameraDepthAttachmentId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                }
                else
                {
                    buffer.SetRenderTarget(cameraColorAttachmentId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                }
            }
            else
            {
                buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            }
        }
        
        void DrawVisibleGeometry(ref RenderingData renderingDta)
        {
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            DrawingSettings drawingSettings = RenderingUtils.CreateDrawingSettings(unlitShaderTagId,
                SortingCriteria.CommonOpaque, ref renderingDta);
            drawingSettings.SetShaderPassName(1, litShaderTagId);
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
            context.DrawSkybox(camera);
            
            CopyColorAndDepth(renderingDta.cameraData);
          
            var sortingSettings = drawingSettings.sortingSettings;
            sortingSettings.criteria = SortingCriteria.CommonTransparent;
            drawingSettings.sortingSettings = sortingSettings;
            filteringSettings.renderQueueRange = RenderQueueRange.transparent;
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
            
            bool cameraTargetResolved = postFXStack.IsActive || !createColorTexture;
            if (!cameraTargetResolved) {
                RenderingUtils.BlitProcedural(buffer, cameraColorAttachmentId, -1);
            }
        }

        void CopyColorAndDepth(CameraData cameraData)
        {
            if (copyOpaqueColor)
            {
                buffer.GetTemporaryRT(cameraOpaqueTextureId, cameraData.cameraTargetDescriptor);
                RenderingUtils.BlitProcedural(buffer, cameraColorAttachmentId, cameraOpaqueTextureId, null, 0);
                ExecuteBuffer();
            }

            if (createDepthTexture)
            {
                buffer.GetTemporaryRT(cameraDepthTextureId, cameraData.cameraTargetDescriptor);
                RenderingUtils.BlitProcedural(buffer, cameraDepthAttachmentId, cameraDepthTextureId, null, 0);
                ExecuteBuffer();
            }

            if (copyOpaqueColor || createDepthTexture)
            {
                SetRenderTarget();
                ExecuteBuffer();
            }
        }
    }
}