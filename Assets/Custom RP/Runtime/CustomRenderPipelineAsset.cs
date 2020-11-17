//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    [CreateAssetMenu(menuName = "Rendering/Custom Render Pipeline")]
    public class CustomRenderPipelineAsset : RenderPipelineAsset
    {
        [SerializeField]
        public bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;

        [SerializeField]
        public bool useLightsPerObject = true;

        [SerializeField]
        public ShadowSettings shadows = default;

        [SerializeField]
        public PostFXSettings postFXSettings = default;

        [SerializeField, Range(0.25f, 2.0f)]
        public float renderScale = 1.0f;

        [SerializeField]
        public MSAAMode MSAA = MSAAMode.Off;

        [SerializeField]
        public bool supportHDR = true;

        [SerializeField]
        public bool requireOpaqueTexture = true;

        [SerializeField]
        public bool requireDepthTexture = true;

        [SerializeField]
        Shader blitShader = default;

        [SerializeField]
        public ColorLUTResolution colorLUTResolution = ColorLUTResolution._32;

        protected override RenderPipeline CreatePipeline()
        {
            return new CustomRenderPipeline(this);
        }

        public enum MSAAMode
        {
            Off = 1,
            _2x = 2,
            _4x = 4,
            _8x = 8
        }

        public enum ColorLUTResolution { 
            _16 = 16, _32 = 32, _64 = 64 
        }

        [System.NonSerialized]
        Material blitMaterial;

        public Material BlitMaterial
        {
            get
            {
                if (blitMaterial == null && blitShader != null)
                {
                    blitMaterial = new Material(blitShader);
                    blitMaterial.hideFlags = HideFlags.HideAndDontSave;
                }
                return blitMaterial;
            }
        }
    }
}