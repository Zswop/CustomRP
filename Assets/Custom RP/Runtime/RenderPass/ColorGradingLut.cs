//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;
using static OpenCS.PostFXSettings;

namespace OpenCS
{
    public class ColorGradingLut
    {
        const string bufferName = "ColorGrading";

        static int colorAdjustmentsId = Shader.PropertyToID("_ColorAdjustments");
        static int colorFilterId = Shader.PropertyToID("_ColorFilter");
        static int whiteBalanceId = Shader.PropertyToID("_WhiteBalance");
        static int splitToningShadowsId = Shader.PropertyToID("_SplitToningShadows");
        static int splitToningHighlightsId = Shader.PropertyToID("_SplitToningHighlights");
        static int channelMixerRedId = Shader.PropertyToID("_ChannelMixerRed");
        static int channelMixerGreenId = Shader.PropertyToID("_ChannelMixerGreen");
        static int channelMixerBlueId = Shader.PropertyToID("_ChannelMixerBlue");
        static int smhShadowsId = Shader.PropertyToID("_SMHShadows");
        static int smhMidTonesId = Shader.PropertyToID("_SMHMidTones");
        static int smhHighLightsId = Shader.PropertyToID("_SMHHighLights");
        static int smhRangeId = Shader.PropertyToID("_SMHRange");

        static int colorGradingLUTParametersId = Shader.PropertyToID("_ColorGradingLUTParameters");

        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        PostFXSettings settings;
        int colorLUTResolution;
        int colorGradingLUTId;

        public void Setup(PostFXSettings postFXSettings, int colorLUTResolution, int colorGradingLUTId)
        {
            this.settings = postFXSettings;
            this.colorLUTResolution = colorLUTResolution;
            this.colorGradingLUTId = colorGradingLUTId;
        }

        public void Render(ScriptableRenderContext context)
        {
            ConfigureColorGrading();

            int lutHeight = colorLUTResolution;
            int lutWidth = lutHeight * lutHeight;
            buffer.GetTemporaryRT(colorGradingLUTId, lutWidth, lutHeight, 0,
                FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
            buffer.SetGlobalVector(colorGradingLUTParametersId, new Vector4(
                lutHeight, 0.5f / lutWidth, 0.5f / lutHeight, lutHeight / (lutHeight - 1f)));

            int pass = (int)PostFXStack.Pass.ColorGrading + (int)settings.ToneMapping.mode;
            RenderingUtils.BlitProcedural(buffer, colorGradingLUTId, colorGradingLUTId, settings.Material, pass);

            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        public void Clearup()
        {
            buffer.ReleaseTemporaryRT(colorGradingLUTId);
        }

        void ConfigureColorAdjustments()
        {
            ColorAdjustmentsSettings colorAdjustments = settings.ColorAdjustments;

            buffer.SetGlobalVector(colorAdjustmentsId, new Vector4(
                Mathf.Pow(2.0f, colorAdjustments.postExposure),
                colorAdjustments.contrast * 0.01f + 1.0f,
                colorAdjustments.hueShift * (1.0f / 360.0f),
                colorAdjustments.saturation * 0.01f + 1.0f
                ));

            buffer.SetGlobalVector(colorFilterId, colorAdjustments.colorFilter.linear);
        }

        void ConfigureWhiteBalance()
        {
            WhiteBalanceSettings whiteBalance = settings.WhiteBalance;
            buffer.SetGlobalVector(whiteBalanceId, ColorUtils.ColorBalanceToLMSCoeffs(
                whiteBalance.temperature, whiteBalance.tint
            ));
        }

        void ConfigureSplitToning()
        {
            SplitToningSettings splitToning = settings.SplitToning;
            Color splitColor = splitToning.shadows;
            splitColor.a = splitToning.balance * 0.01f;
            buffer.SetGlobalColor(splitToningShadowsId, splitColor);
            buffer.SetGlobalColor(splitToningHighlightsId, splitToning.highlights);
        }

        void ConfigureChannelMixer()
        {
            ChannelMixerSettings channelMixer = settings.ChannelMixer;
            buffer.SetGlobalVector(channelMixerRedId, channelMixer.red);
            buffer.SetGlobalVector(channelMixerGreenId, channelMixer.green);
            buffer.SetGlobalVector(channelMixerBlueId, channelMixer.blue);
        }

        void ConfigureShadowsMidtonesHighlights()
        {
            ShadowsMidtonesHighlightsSettings smh = settings.ShadowsMidtonesHighlights;
            buffer.SetGlobalVector(smhShadowsId, smh.shadows.linear);
            buffer.SetGlobalVector(smhMidTonesId, smh.midtones.linear);
            buffer.SetGlobalVector(smhHighLightsId, smh.highlights.linear);
            buffer.SetGlobalVector(smhRangeId, new Vector4(smh.shadowsStart, smh.shadowsEnd,
                smh.highlightsStart, smh.highLightsEnd));
        }

        void ConfigureColorGrading()
        {
            ConfigureColorAdjustments();
            ConfigureWhiteBalance();
            ConfigureSplitToning();
            ConfigureChannelMixer();
            ConfigureShadowsMidtonesHighlights();
        }
    }
}