//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public class DepthPrepare
    {
        const string bufferName = "DepthOnly";

        static ShaderTagId depthOnlyShaderTagId = new ShaderTagId("DepthOnly");

        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        //ScriptableRenderContext context;
        //RenderTextureDescriptor depthDescriptor;
        int cameraDepthTextureId = -1;

        public void Setup(ScriptableRenderContext context, ref CullingResults cullingResults, 
            ref RenderingData renderingData, int cameraDepthTextureId)
        {
            this.cameraDepthTextureId = cameraDepthTextureId;

            ref CameraData cameraData = ref renderingData.cameraData;
            RenderTextureDescriptor depthDescriptor = cameraData.cameraTargetDescriptor;
            depthDescriptor.colorFormat = RenderTextureFormat.Depth;
            depthDescriptor.depthBufferBits = 32;
            depthDescriptor.msaaSamples = 1;

            buffer.GetTemporaryRT(cameraDepthTextureId, depthDescriptor, FilterMode.Point);
            buffer.SetRenderTarget(cameraDepthTextureId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            buffer.ClearRenderTarget(true, false, Color.clear);

            buffer.BeginSample(bufferName);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();

            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            DrawingSettings depthOnlyDrawSettings = RenderingUtils.CreateDrawingSettings(depthOnlyShaderTagId,
                SortingCriteria.CommonOpaque, ref renderingData);
            depthOnlyDrawSettings.perObjectData = PerObjectData.None;

            context.DrawRenderers(cullingResults, ref depthOnlyDrawSettings, ref filteringSettings);

            buffer.EndSample(bufferName);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        public void Cleanup()
        {
            buffer.ReleaseTemporaryRT(cameraDepthTextureId);
        }
    }
}