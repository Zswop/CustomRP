//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
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
            ColorGradingFinal,
            FXAALuminance,
            FXAA,
        }

        const string bufferName = "Post FX";
        //static int fxSourceId = Shader.PropertyToID("_PostFXSource");
        static int fxSourceLowMipId = Shader.PropertyToID("_PostFXSourceLowMip");

        static int depthStripesResultId = Shader.PropertyToID("_DepthStripesResult");
        static int depthTexId = Shader.PropertyToID("_DepthTex");

        static int bloomThresholdId = Shader.PropertyToID("_BloomThreshold");
        static int bloomIntensityId = Shader.PropertyToID("_BloomIntensity");
        static int bloomResultId = Shader.PropertyToID("_BloomResult");

        static int blurTempId = Shader.PropertyToID("_BlurTemp");
        static int blurResultId = Shader.PropertyToID("_BlurResultId");
        
        static int colorGradingLUTParametersId = Shader.PropertyToID("_ColorGradingLUTParameters");
        static int toneMappingResultId = Shader.PropertyToID("_ToneMappingResult");

        static int fxaaLuminanceId = Shader.PropertyToID("_FXAALuminance");
        static int contrastThreshold = Shader.PropertyToID("_ContrastThreshold");
        
        const int maxBloomPyramidLevels = 8;
        private static int[] _BloomMipUp;
        private static int[] _BloomMipDown;

        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        private bool postProcessEnabled = false;
        private RenderTexture targetTexture;
        Camera camera;

        RenderTextureDescriptor baseDescriptor;
        PostFXSettings settings;
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

        public void Setup(ref CameraData cameraData, PostFXSettings settings, int colorLUTResolution)
        {
            this.camera = cameraData.camera;
            this.targetTexture = cameraData.targetTexture;
            this.baseDescriptor = cameraData.cameraTargetDescriptor;
            this.settings = cameraData.cameraType <= CameraType.SceneView ? settings : null;
            this.postProcessEnabled = cameraData.postProcessEnabled;
            this.colorLUTResolution = colorLUTResolution;

            ApplySceneViewState();
        }

        public RenderTextureDescriptor GetDescriptor(int width, int height, int depthBufferBits = 0)
        {
            RenderTextureDescriptor desc = baseDescriptor;
            desc.depthBufferBits = depthBufferBits;
            desc.msaaSamples = 1;
            desc.height = height;
            desc.width = width;
            return desc;
        }

        public RenderTextureDescriptor GetDefaultDescriptor()
        {
            return GetDescriptor(baseDescriptor.width, baseDescriptor.height, 0);
        }

        public void Render(ScriptableRenderContext context, int cameraColorId)
        {
            bool enableDepthStripes = settings.DepthStripes;
            bool enableBlur = settings.Blur.maxIterations > 0;
            bool enableBloom = settings.Bloom.maxIterations > 0 && settings.Bloom.intensity > 0f;
            bool enableToneMapping = settings.ToneMapping.mode != ToneMappingSettings.Mode.None;
            bool enableFXAA = settings.FXAA.luminanceSource != FXAASettings.LuminanceMode.None;
            
            int srcId = cameraColorId;
            int dstId = cameraColorId;
            var descriptor = GetDefaultDescriptor();

            //TODO: swap temp result

            if (enableDepthStripes)
            {
                buffer.GetTemporaryRT(depthStripesResultId, descriptor, FilterMode.Bilinear);
                ApplyDepthStripes(srcId, depthStripesResultId);
                dstId = srcId = depthStripesResultId;
            }

            if (enableBlur)
            {
                buffer.GetTemporaryRT(blurResultId, descriptor, FilterMode.Bilinear);
                ApplyBlur(srcId, blurResultId);
                dstId = srcId = blurResultId;
            }

            if (enableBloom)
            {
                buffer.GetTemporaryRT(bloomResultId, descriptor, FilterMode.Bilinear);
                ApplyBloom(srcId, bloomResultId);
                dstId = srcId = bloomResultId;
            }

            if (enableToneMapping)
            {
                buffer.GetTemporaryRT(toneMappingResultId, descriptor, FilterMode.Bilinear);
                ApplyToneMap(srcId, toneMappingResultId);
                dstId = srcId = toneMappingResultId;
            }

            if (enableFXAA)
            {
                ApplyFXAA(srcId, -1);
                dstId = -1;
            }

            if (dstId != -1)
            {
                Draw(srcId, -1, Pass.Copy);
            }

            if (enableDepthStripes) { buffer.ReleaseTemporaryRT(depthStripesResultId); }
            if (enableToneMapping) { buffer.ReleaseTemporaryRT(toneMappingResultId); }
            if (enableBloom) { buffer.ReleaseTemporaryRT(bloomResultId); }
            if (enableBlur) { buffer.ReleaseTemporaryRT(blurResultId); }

            targetTexture = null;
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        void Draw(int from, int to, Pass pass)
        {
            var target = to != -1 ? to : (targetTexture != null ? 
                new RenderTargetIdentifier(targetTexture) : BuiltinRenderTextureType.CameraTarget);
            RenderingUtils.BlitProcedural(buffer, from, target, settings.Material, (int)pass);
        }

        void ApplyDepthStripes(int sourceId, int targetId)
        {
            buffer.BeginSample("Depth Stripes");
            Draw(sourceId, targetId, Pass.DepthStripes);
            buffer.EndSample("Depth Stripes");
        }

        void ApplyBlur(int sourceId, int targetId)
        {
            buffer.BeginSample("Blur");
            buffer.GetTemporaryRT(blurTempId, GetDefaultDescriptor(), FilterMode.Bilinear);

            int iterations = settings.Blur.maxIterations;
            bool changeTarget = iterations % 2 == 0;
            int srcId = sourceId;
            for (int i = 0; i < iterations; ++i)
            {
                int dstId = changeTarget ? blurTempId : targetId;
                Draw(srcId, dstId, Pass.Blur);
                changeTarget = !changeTarget;
                srcId = dstId;
            }

            buffer.ReleaseTemporaryRT(blurTempId);
            buffer.EndSample("Blur");
        }

        void ApplyBloom(int sourceId, int targetId)
        {
            buffer.BeginSample("Bloom");
            PostFXSettings.BloomSettings bloom = settings.Bloom;
            int width = baseDescriptor.width >> 1, height = baseDescriptor.height >> 1;

            // prefilter
            Vector4 threshold;
            threshold.x = Mathf.GammaToLinearSpace(bloom.threshold);
            threshold.y = threshold.x * bloom.thresholdKnee;
            threshold.z = 2f * threshold.y;
            threshold.w = 0.25f / (threshold.y + 0.00001f);
            threshold.y -= threshold.x;
            buffer.SetGlobalVector(bloomThresholdId, threshold);

            var description = GetDescriptor(width, height);
            buffer.GetTemporaryRT(_BloomMipDown[0], description, FilterMode.Bilinear);
            //buffer.GetTemporaryRT(_BloomMipUp[0], width, height, 0, FilterMode.Bilinear, format);
            Draw(sourceId, _BloomMipDown[0], Pass.BloomPrefilter);

            // downsampling + gaussian Blur
            int lastDown = _BloomMipDown[0];
            int mipCount = bloom.maxIterations;
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

            //Draw(lastDown, BuiltinRenderTextureType.CameraTarget, Pass.Copy);

            var intensity = 1f;
            var finalIntersity = bloom.intensity;
            var combinePass = Pass.BloomAdd;
            var finalPass = Pass.BloomAdd;
            if (bloom.mode == PostFXSettings.BloomSettings.Mode.Scattering)
            {
                intensity = bloom.scatter;
                finalIntersity = Mathf.Min(finalIntersity, 0.95f);
                combinePass = Pass.BloomScatter;
                finalPass = Pass.BloomScatterFinal;
            }

            // upsampling + bicubic filter
            int lowMip = lastDown;
            buffer.SetGlobalFloat(bloomIntensityId, intensity);
            for (int i = mipCount - 2; i > 0; i--)
            {
                int hightMip = _BloomMipDown[i];
                int dstMip = _BloomMipUp[i];

                buffer.SetGlobalTexture(fxSourceLowMipId, lowMip);
                Draw(hightMip, dstMip, combinePass);
                lowMip = dstMip;
            }
            
            buffer.SetGlobalTexture(fxSourceLowMipId, lowMip);
            buffer.SetGlobalFloat(bloomIntensityId, finalIntersity);
            Draw(sourceId, targetId, finalPass);

            // cleanup
            for (int i = 0; i < mipCount; ++i)
            {
                buffer.ReleaseTemporaryRT(_BloomMipDown[i]);
                if (i > 0) buffer.ReleaseTemporaryRT(_BloomMipUp[i]);
            }            
            buffer.EndSample("Bloom");
        }

        void ApplyToneMap(int sourceId, int targetId)
        {
            buffer.BeginSample("ToneMapping");

            int lutHeight = colorLUTResolution;
            int lutWidth = lutHeight * lutHeight;
            buffer.SetGlobalVector(colorGradingLUTParametersId, new Vector4(
                1f / lutWidth, 1f / lutHeight, lutHeight - 1f));
            Draw(sourceId, targetId, Pass.ColorGradingFinal);

            buffer.EndSample("ToneMapping");
        }

        void ApplyFXAA(int sourceId, int targetId)
        {
            buffer.BeginSample("FXAA");
            FXAASettings fxaa = settings.FXAA;
            buffer.GetTemporaryRT(fxaaLuminanceId, GetDefaultDescriptor(), FilterMode.Bilinear);

            Draw(sourceId, fxaaLuminanceId, Pass.FXAALuminance);

            Vector4 contrastThresh = new Vector4(fxaa.contrastThreshold, fxaa.relativeThreshold,
                fxaa.subpixelBlending, 0f);
            buffer.SetGlobalVector(contrastThreshold, contrastThresh);
            Draw(fxaaLuminanceId, targetId, Pass.FXAA);

            buffer.ReleaseTemporaryRT(fxaaLuminanceId);
            buffer.EndSample("FXAA");
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