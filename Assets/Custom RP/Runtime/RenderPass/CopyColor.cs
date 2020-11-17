//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public class ColorCopy
    {
        const string bufferName = "CopyColor";

        CommandBuffer buffer = new CommandBuffer { name = bufferName };
        
        private RenderTextureDescriptor targetDescriptor;
        private int destinationId;

        public void Setup(int destinationId, RenderTextureDescriptor targetDescriptor)
        {
            this.destinationId = destinationId;
            this.targetDescriptor = targetDescriptor;
        }

        public void Render(ScriptableRenderContext context, int sourceId, Material material, int pass)
        {
            buffer.GetTemporaryRT(destinationId, targetDescriptor);
            RenderingUtils.BlitProcedural(buffer, sourceId, destinationId, material, pass);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        public void Clearup()
        {
            buffer.ReleaseTemporaryRT(destinationId);
        }
    }
}