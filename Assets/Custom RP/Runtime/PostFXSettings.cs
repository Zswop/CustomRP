//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
    [CreateAssetMenu(menuName = "Rendering/Custom Post FX Settings")]
    public class PostFXSettings : ScriptableObject
    {
        [SerializeField]
        Shader shader = default;

        [System.NonSerialized]
        Material material;

        public bool DepthStripes;

        [System.Serializable]
        public struct BlurSettings
        {
            [Range(0f, 16f)]
            public int maxIterations;
        }

        [SerializeField]
        BlurSettings blur = new BlurSettings() {
            maxIterations = 3,
        };

        [System.Serializable]
        public struct BloomSettings
        {
            [Range(0f, 8f)]
            public int maxIterations;

            [Min(1f)]
            public int downscaleLimit;

            [Min(0f)]
            public float threshold;

            [Range(0f, 1f)]
            public float thresholdKnee;

            [Min(0f)]
            public float intensity;

            public enum Mode { Scattering, Additive }

            public Mode mode;

            [Range(0.05f, 0.95f)]
            public float scatter;
        }

        [SerializeField]
        BloomSettings bloom = new BloomSettings(){
            maxIterations = 3,
            downscaleLimit = 1,
            threshold = 0.5f,
            thresholdKnee = 0.5f,
            intensity = 1f,

            mode = BloomSettings.Mode.Scattering,
            scatter = 0.7f,
        };

        [System.Serializable]
        public struct ColorAdjustmentsSettings 
        {
            public float postExposure;

            [Range(-100f, 100f)]
            public float contrast;

            [ColorUsage(false, true)]
            public Color colorFilter;

            [Range(-180f, 180f)]
            public float hueShift;

            [Range(-100f, 100f)]
            public float saturation;
        }

        [SerializeField]
        ColorAdjustmentsSettings colorAdjustments = new ColorAdjustmentsSettings()
        {
            colorFilter = Color.white,
        };

        [System.Serializable]
        public struct WhiteBalanceSettings
        {
            [Range(-100f, 100f)]
            public float temperature;

            [Range(-100f, 100f)]
            public float  tint;
        }

        [SerializeField]
        WhiteBalanceSettings whiteBalance = default;

        [System.Serializable]
        public struct SplitToningSettings
        {
            [ColorUsage(false)]
            public Color shadows, highlights;

            [Range(-100f, 100f)]
            public float balance;
        }

        [SerializeField]
        SplitToningSettings splitToning = new SplitToningSettings
        {
            shadows = Color.gray,
            highlights = Color.gray,
            balance = 0.0f,
        };

        [System.Serializable]
        public struct ChannelMixerSettings
        {
            public Vector3 red, green, blue;
        }

        [SerializeField]
        ChannelMixerSettings channelMixer = new ChannelMixerSettings
        {
            red = Vector3.right,
            green = Vector3.up,
            blue = Vector3.forward
        };

        [System.Serializable]
        public struct ShadowsMidtonesHighlightsSettings
        {
            [ColorUsage(false, true)]
            public Color shadows, midtones, highlights;

            [Range(0f, 2f)]
            public float shadowsStart, shadowsEnd, highlightsStart, highLightsEnd;
        }

        [SerializeField]
        ShadowsMidtonesHighlightsSettings  shadowsMidtonesHighlights = new ShadowsMidtonesHighlightsSettings
        {
            shadows = Color.white,
            midtones = Color.white,
            highlights = Color.white,
            shadowsStart = 0.0f,
            shadowsEnd = 0.3f,
            highlightsStart = 0.55f,
            highLightsEnd = 1f
        };
        
        [System.Serializable]
        public struct ToneMappingSettings
        {
            public enum Mode { None, ACES, Neutral }
            public Mode mode;
        }

        [SerializeField]
        ToneMappingSettings tonemapping = new ToneMappingSettings()
        {
            mode = ToneMappingSettings.Mode.ACES,
        };

        [System.Serializable]
        public struct FXAASettings
        {
            public enum LuminanceMode { None, Calculate }
            public LuminanceMode luminanceSource;

            [Range(0.0312f, 0.0833f)]
            public float contrastThreshold;

            [Range(0.063f, 0.333f)]
            public float relativeThreshold;

            [Range(0f, 1f)]
            public float subpixelBlending;
        }

        [SerializeField]
        FXAASettings fxaa = new FXAASettings()
        {
            luminanceSource = FXAASettings.LuminanceMode.Calculate,
            contrastThreshold = 0.0312f,
            relativeThreshold = 0.063f,
            subpixelBlending = 1.0f,
        };

        public Material Material
        {
            get
            {
                if (material == null && shader != null)
                {
                    material = new Material(shader);
                    material.hideFlags = HideFlags.HideAndDontSave;
                }
                return material;
            }
        }

        public BlurSettings Blur => blur;

        public BloomSettings Bloom => bloom;

        public ColorAdjustmentsSettings ColorAdjustments => colorAdjustments;

        public WhiteBalanceSettings WhiteBalance => whiteBalance;

        public SplitToningSettings SplitToning => splitToning;

        public ChannelMixerSettings ChannelMixer => channelMixer;

        public ShadowsMidtonesHighlightsSettings ShadowsMidtonesHighlights => shadowsMidtonesHighlights;

        public ToneMappingSettings ToneMapping => tonemapping;

        public FXAASettings FXAA => fxaa;
    }
}