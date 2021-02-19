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

        [SerializeField]
        Shader uberPost = default;

        public bool DepthStripes;

        [System.Serializable]
        public struct BlurSettings
        {
            [Range(0f, 16f)]
            public int maxIterations;

            [Range(0f, 5f)]
            public float raidus;
        }

        [SerializeField]
        BlurSettings blur = new BlurSettings() {
            maxIterations = 3,
            raidus = 0.5f,
        };

        [System.Serializable]
        public struct BloomSettings
        {
            [Range(0f, 5f)]
            public int diffusion;

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
        BloomSettings bloom = new BloomSettings()
        {
            diffusion = 3,
            threshold = 0.5f,
            thresholdKnee = 0.5f,
            intensity = 0.0f,

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
        public struct VignetteSettings
        {
            [ColorUsage(false)]
            public Color color;

            public Vector2 center;

            [Range(0f, 1.0f)]
            public float intensity;

            [Range(0.01f, 1.0f)]
            public float smoothness;

            public bool rounded;
        }

        [SerializeField]
        VignetteSettings vignette = new VignetteSettings()
        {
            color = Color.black,
            center = Vector2.zero,
            intensity = 0.0f,
            smoothness = 0.2f,
            rounded = false,
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

        [System.Serializable]
        public struct DepthOfFieldSettings
        {
            public bool enbable;

            [Min(0.1f)]
            public float focusDistance;

            [Range(1f, 32f)]
            public float aperture;

            [Range(1f, 300f)]
            public float focalLength;

            [Range(1f, 15f)]
            public float maxRadius;
        }

        [SerializeField]
        Shader dofShader = default;

        [SerializeField]
        DepthOfFieldSettings depthOfField = new DepthOfFieldSettings
        {
            enbable = false,
            focusDistance = 10f,
            aperture = 5.6f,
            focalLength = 50f,
            maxRadius = 4f,
        };

        [System.NonSerialized]
        Material dofMaterial;

        public Material DofMaterial
        {
            get
            {
                if (dofMaterial == null && dofShader != null)
                {
                    dofMaterial = UnityEngine.Rendering.CoreUtils.CreateEngineMaterial(dofShader);
                }
                return dofMaterial;
            }
        }

        [System.NonSerialized]
        Material material;

        public Material Material
        {
            get
            {
                if (material == null && shader != null)
                {
                    //material = new Material(shader);
                    //material.hideFlags = HideFlags.HideAndDontSave;
                    material = UnityEngine.Rendering.CoreUtils.CreateEngineMaterial(shader);
                }
                return material;
            }
        }

        [System.NonSerialized]
        Material uberMaterial;

        public Material UberMaterial
        {
            get
            {
                if (uberMaterial == null && uberPost != null)
                {
                    uberMaterial = UnityEngine.Rendering.CoreUtils.CreateEngineMaterial(uberPost);
                }
                return uberMaterial;
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

        public VignetteSettings Vignette => vignette;

        public DepthOfFieldSettings DepthOfField => depthOfField;
    }
}