//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using UnityEngine.Experimental.Rendering;

using static OpenCS.PostFXSettings;

namespace OpenCS
{
    public partial class PostFXStack
    {
        public enum Pass
        {
            DepthStripes,
            Blur,
            BloomPrefilter,
            BloomHorizontal,
            BloomVertical,
            BloomScatter,
            BloomAdd,
            BloomScatterFinal,
            Copy,
            ColorGrading,
            ColorGradingACES,
            ColorGradingNeutral,
            FXAA,
        }

        const string bufferName = "Post FX";
        
        static readonly int tempTextureId = Shader.PropertyToID("_PostFXTempTexture");
        static readonly int blurRadiusId = Shader.PropertyToID("_BlurRadius");
        static readonly int blurTempId = Shader.PropertyToID("_BlurTemp");

        static readonly int bloomThresholdId = Shader.PropertyToID("_BloomThreshold");
        static readonly int bloomIntensityId = Shader.PropertyToID("_BloomIntensity");
        static readonly int bloomLowMipId = Shader.PropertyToID("_BloomLowMip");
        static readonly int bloomTextureId = Shader.PropertyToID("_BloomTexture");

        static readonly int vignetteParams1Id = Shader.PropertyToID("_VignetteParams1");
        static readonly int vignetteParams2Id = Shader.PropertyToID("_VignetteParams2");

        static readonly string bloomAddStr = "_BLOOM_ADD";
        static readonly string bloomScatterStr = "_BLOOM_SCATTER";
        static readonly string vignetteStr = "_VIGNETTE";

        static readonly int colorGradingLUTParametersId = Shader.PropertyToID("_ColorGradingLUTParameters");
        static readonly int lutTextureId = Shader.PropertyToID("_LUTTexture");

        static readonly int contrastThreshold = Shader.PropertyToID("_ContrastThreshold");

        static readonly int cocParamsId = Shader.PropertyToID("_CoCParams");
        static readonly int cocTextureId = Shader.PropertyToID("_CoCTexture");
        static readonly int dofPingTextureId = Shader.PropertyToID("_DoFPingTexture");
        static readonly int dofPongTextureId = Shader.PropertyToID("_DoFPongTexture");
        static readonly int dofTextureId = Shader.PropertyToID("_DoFTexture");

        const int maxBloomPyramidLevels = 16;
        private static int[] _BloomMipUp;
        private static int[] _BloomMipDown;

        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        private bool postProcessEnabled = false;
        private RenderTexture targetTexture;
        Camera camera;

        RenderTextureDescriptor baseDescriptor;
        PostFXSettings settings;

        RenderTargetIdentifier colorLUTId;
        int colorLUTResolution;

        public bool IsActive { get { return settings != null && postProcessEnabled; } }

        public PostFXStack()
        {
            _BloomMipUp = new int[maxBloomPyramidLevels];
            _BloomMipDown = new int[maxBloomPyramidLevels];
            for (int i = 0; i < maxBloomPyramidLevels; ++i)
            {
                _BloomMipUp[i] = Shader.PropertyToID("BloomMipUp" + i);
                _BloomMipDown[i] = Shader.PropertyToID("BloomMipDown" + i);
            }
        }

        public void Setup(ref CameraData cameraData, PostFXSettings settings, 
            RenderTargetIdentifier internalLut, int colorLUTResolution)
        {
            this.camera = cameraData.camera;
            this.targetTexture = cameraData.targetTexture;
            this.baseDescriptor = cameraData.cameraTargetDescriptor;
            this.colorLUTId = internalLut;
            this.colorLUTResolution = colorLUTResolution;

            this.settings = cameraData.cameraType <= CameraType.SceneView ? settings : null;
            this.postProcessEnabled = cameraData.postProcessEnabled;
            ApplySceneViewState();
        }

        public RenderTextureDescriptor GetDescriptor(int width, int height, GraphicsFormat format, int depthBufferBits = 0)
        {
            RenderTextureDescriptor desc = baseDescriptor;
            desc.depthBufferBits = depthBufferBits;
            desc.msaaSamples = 1;
            desc.height = height;
            desc.width = width;
            desc.graphicsFormat = format;
            return desc;
        }

        public RenderTextureDescriptor GetDefaultDescriptor()
        {
            return GetDescriptor(baseDescriptor.width, baseDescriptor.height, baseDescriptor.graphicsFormat, 0);
        }

        public void Render(ScriptableRenderContext context, int cameraColorId)
        {
            RenderTextureDescriptor descriptor = GetDefaultDescriptor();
            bool tempTargetUsed = false;
            int srcId = cameraColorId;
            int dstId = -1;

            // Utilities to simplify intermediate target management
            int GetSource() => srcId;

            int GetDestination()
            {
                if (dstId == -1)
                {
                    buffer.GetTemporaryRT(tempTextureId, descriptor, FilterMode.Bilinear);
                    dstId = tempTextureId;
                    tempTargetUsed = true;
                }
                return dstId;
            }

            void Swap() => CoreUtils.Swap(ref srcId, ref dstId);

            bool enableDepthStripes = settings.DepthStripes;
            if (enableDepthStripes)
            {
                ApplyDepthStripes(GetSource(), GetDestination());
                Swap();
            }

            bool enableBlur = settings.Blur.maxIterations > 0;
            if (enableBlur)
            {
                ApplyKawaseBlur(GetSource(), GetDestination());
                Swap();
            }

            bool enableDOF = settings.DepthOfField.enbable;
            if (enableDOF)
            {
                var dofMat = settings.DofMaterial;
                ApplyDepthOfField(GetSource(), GetDestination(), dofMat);
                Swap();
            }

            bool enableBloom = settings.Bloom.intensity > 0f;
            bool applyFinal = settings.FXAA.luminanceSource != FXAASettings.LuminanceMode.None;

            // Uber Post setup
            {
                var uber = settings.UberMaterial;
                settings.UberMaterial.shaderKeywords = null;
                if (enableBloom) { SetupBloom(GetSource(), uber); }
                SetupColorGrading(uber);
                SetupVignette(uber);

                buffer.BeginSample("UberPost");
                var cameraTarget = applyFinal ? GetDestination() : -1;
                Draw(GetSource(), cameraTarget, uber, 0);
                if (applyFinal) { Swap(); }
                buffer.EndSample("UberPost");
            }

            var sourceForFinalPass = GetSource();
            if (applyFinal) { ApplyFinal(sourceForFinalPass, -1); }

            if (enableBloom) { buffer.ReleaseTemporaryRT(_BloomMipUp[0]); }
            if (tempTargetUsed) { buffer.ReleaseTemporaryRT(tempTextureId); }

            targetTexture = null;
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        RenderTargetIdentifier GetFinalTarget()
        {
            return (targetTexture != null ? new RenderTargetIdentifier(targetTexture) : BuiltinRenderTextureType.CameraTarget);
        }

        void Draw(int from, int to, Pass pass)
        {
            Draw(from, to, settings.Material, (int)pass);
        }

        void Draw(int from, int to, Material material, int pass)
        {
            var target = to != -1 ? to : GetFinalTarget();
            RenderingUtils.BlitProcedural(buffer, from, target, material, (int)pass);
        }

        void ApplyDepthStripes(int sourceId, int targetId)
        {
            buffer.BeginSample("Depth Stripes");
            Draw(sourceId, targetId, Pass.DepthStripes);
            buffer.EndSample("Depth Stripes");
        }

        void ApplyKawaseBlur(int sourceId, int targetId)
        {
            buffer.BeginSample("Blur");
            buffer.GetTemporaryRT(blurTempId, GetDefaultDescriptor(), FilterMode.Bilinear);

            int iterations = settings.Blur.maxIterations;
            bool changeTarget = iterations % 2 == 0;
            int srcId = sourceId;
            for (int i = 0; i < iterations; ++i)
            {
                var radius = settings.Blur.raidus + i;
                buffer.SetGlobalFloat(blurRadiusId, radius);
                int dstId = changeTarget ? blurTempId : targetId;
                Draw(srcId, dstId, Pass.Blur);
                changeTarget = !changeTarget;
                srcId = dstId;
            }

            buffer.ReleaseTemporaryRT(blurTempId);
            buffer.EndSample("Blur");
        }

        void SetupBloom(int sourceId, Material uber)
        {
            buffer.BeginSample("Bloom");
            PostFXSettings.BloomSettings bloom = settings.Bloom;
            int width = baseDescriptor.width >> 1;
            int height = baseDescriptor.height >> 1;

            // prefilter
            Vector4 threshold;
            threshold.x = Mathf.GammaToLinearSpace(bloom.threshold);
            threshold.y = threshold.x * bloom.thresholdKnee;
            threshold.z = 2f * threshold.y;
            threshold.w = 0.25f / (threshold.y + 0.00001f);
            threshold.y -= threshold.x;
            buffer.SetGlobalVector(bloomThresholdId, threshold);

            var description = GetDescriptor(width, height, baseDescriptor.graphicsFormat);
            buffer.GetTemporaryRT(_BloomMipDown[0], description, FilterMode.Bilinear);
            buffer.GetTemporaryRT(_BloomMipUp[0], description, FilterMode.Bilinear);
            Draw(sourceId, _BloomMipDown[0], Pass.BloomPrefilter);

            // Determine the iteration count
            int maxSize = Mathf.Max(width, height);
            int iterations = Mathf.FloorToInt(Mathf.Log(maxSize, 2f) - 1);
            int mipCount = Mathf.Clamp(iterations - bloom.diffusion, 1, maxBloomPyramidLevels);

            // downsampling + gaussian Blur
            int lastDown = _BloomMipDown[0];
            for (int i = 1; i < mipCount; i++)
            {
                width = Mathf.Max(1, width >> 1);
                height = Mathf.Max(1, height >> 1);

                int mipDown = _BloomMipDown[i];
                int mipUp = _BloomMipUp[i];

                description.width = width;
                description.height = height;
                buffer.GetTemporaryRT(mipDown, description, FilterMode.Bilinear);
                buffer.GetTemporaryRT(mipUp, description, FilterMode.Bilinear);

                Draw(lastDown, mipUp, Pass.BloomHorizontal);
                Draw(mipUp, mipDown, Pass.BloomVertical);
                lastDown = mipDown;
            }

            var intensity = 1f;
            var finalIntersity = bloom.intensity;
            var combinePass = Pass.BloomAdd;
            if (bloom.mode == BloomSettings.Mode.Scattering)
            {
                intensity = bloom.scatter;
                finalIntersity = Mathf.Min(finalIntersity, 0.95f);
                combinePass = Pass.BloomScatter;
            }

            // upsampling + bicubic filter
            int lowMip = lastDown;
            buffer.SetGlobalFloat(bloomIntensityId, intensity);
            for (int i = mipCount - 2; i >= 0; i--)
            {
                int hightMip = _BloomMipDown[i];
                int dstMip = _BloomMipUp[i];

                buffer.SetGlobalTexture(bloomLowMipId, lowMip);
                Draw(hightMip, dstMip, combinePass);
                lowMip = dstMip;
            }

            // cleanup
            for (int i = 0; i < mipCount; ++i)
            {
                buffer.ReleaseTemporaryRT(_BloomMipDown[i]);
                if (i > 0) buffer.ReleaseTemporaryRT(_BloomMipUp[i]);
            }
            buffer.EndSample("Bloom");

            // Setup bloom on uber
            uber.SetVector(bloomThresholdId, threshold);
            uber.SetFloat(bloomIntensityId, finalIntersity);
            buffer.SetGlobalTexture(bloomTextureId, _BloomMipUp[0]);
            if (bloom.mode == BloomSettings.Mode.Scattering)
                uber.EnableKeyword(bloomScatterStr);
            else
                uber.EnableKeyword(bloomAddStr);
                
        }

        void SetupColorGrading(Material uber)
        {
            int lutHeight = colorLUTResolution;
            int lutWidth = lutHeight * lutHeight;
            buffer.SetGlobalTexture(lutTextureId, colorLUTId);
            uber.SetVector(colorGradingLUTParametersId, new Vector4(
                1f / lutWidth, 1f / lutHeight, lutHeight - 1f));
        }

        void SetupVignette(Material uber)
        {
            var color = settings.Vignette.color;
            var center = settings.Vignette.center;
            var aspectRatio = baseDescriptor.width / (float)baseDescriptor.height;

            if (settings.Vignette.intensity > 0.0f)
                uber.EnableKeyword(vignetteStr);
            
            uber.SetVector(vignetteParams1Id, new Vector4(
                color.r, color.g, color.b, 
                settings.Vignette.rounded ? aspectRatio : 1f)
            );
            uber.SetVector(vignetteParams2Id, new Vector4(
                center.x, center.y,
                settings.Vignette.intensity * 3f,
                settings.Vignette.smoothness * 5f)
            );
        }      

        void ApplyFinal(int sourceId, int targetId)
        {
            buffer.BeginSample("FXAA");
            FXAASettings fxaa = settings.FXAA;
            Vector4 contrastThresh = new Vector4(fxaa.contrastThreshold, fxaa.relativeThreshold,
                fxaa.subpixelBlending, 0f);
            buffer.SetGlobalVector(contrastThreshold, contrastThresh);
            Draw(sourceId, targetId, Pass.FXAA);

            buffer.EndSample("FXAA");
        }

        void ApplyDepthOfField(int sourceId, int targetId, Material dofMat)
        {
            buffer.BeginSample("DepthOfField");
            int wh = baseDescriptor.width;
            int hh = baseDescriptor.height;

            float F = settings.DepthOfField.focalLength / 1000f;
            float A = settings.DepthOfField.focalLength / settings.DepthOfField.aperture;
            float P = settings.DepthOfField.focusDistance;
            
            float maxCoC = (A * F) / (P - F);
            float rcpAspect = 1f / (wh / (float)hh);
            float maxRadius = Mathf.Min(0.05f, settings.DepthOfField.maxRadius / hh);
            buffer.SetGlobalVector(cocParamsId, new Vector4(P, maxCoC, maxRadius, rcpAspect));
            
            var cocDescriptor = GetDescriptor(wh, hh, GraphicsFormat.R8_UNorm);
            buffer.GetTemporaryRT(cocTextureId, cocDescriptor, FilterMode.Bilinear);
            var dofDescriptor = GetDescriptor(wh/2, hh/2, GraphicsFormat.R16G16B16A16_SFloat);
            buffer.GetTemporaryRT(dofPingTextureId, dofDescriptor, FilterMode.Bilinear);
            buffer.GetTemporaryRT(dofPongTextureId, dofDescriptor, FilterMode.Bilinear);

            Draw(sourceId, cocTextureId, dofMat, 0);
            buffer.SetGlobalTexture(cocTextureId, cocTextureId);

            Draw(sourceId, dofPingTextureId, dofMat, 1);
            Draw(dofPingTextureId, dofPongTextureId, dofMat, 2);
            Draw(dofPongTextureId, dofPingTextureId, dofMat, 3);

            buffer.SetGlobalTexture(dofTextureId, dofPingTextureId);
            Draw(sourceId, targetId, dofMat, 4);

            buffer.ReleaseTemporaryRT(cocTextureId);
            buffer.ReleaseTemporaryRT(dofPongTextureId);
            buffer.ReleaseTemporaryRT(dofPingTextureId);
            buffer.EndSample("DepthOfField");
        }

        partial void ApplySceneViewState();

#if UNITY_EDITOR
        partial void ApplySceneViewState()
        {
            if (camera.cameraType == CameraType.SceneView && 
                !SceneView.currentDrawingSceneView.sceneViewState.showImageEffects)
            {
                postProcessEnabled = false;
            }
        }
#endif
    }
}