//Writing by Jiayun Li
//Copyright (c) 2021

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public abstract class ScriptableRenderPass
    {
        RenderTargetIdentifier _colorAttachment = BuiltinRenderTextureType.CameraTarget;
        RenderTargetIdentifier _depthAttachment = BuiltinRenderTextureType.CameraTarget;
        ClearFlag _clearFlag = ClearFlag.None;
        Color _clearColor = Color.black;

        internal bool overrideCameraTarget { get; set; }

        public RenderTargetIdentifier colorAttachment
        {
            get => _colorAttachment;
        }

        public RenderTargetIdentifier depthAttachment
        {
            get => _depthAttachment;
        }

        public ClearFlag clearFlag
        {
            get => _clearFlag;
        }

        public Color clearColor
        {
            get => _clearColor;
        }

        public void ConfigureTarget(RenderTargetIdentifier colorAttachment, RenderTargetIdentifier depthAttachment)
        {
            overrideCameraTarget = true;
            _colorAttachment = colorAttachment;
            _depthAttachment = depthAttachment;
        }

        public virtual void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        { 
        }

        public abstract void Execute(ScriptableRenderContext context, ref RenderingData renderingData);

        public virtual void FrameCleanup(CommandBuffer cmd)
        {
        }
    }
}