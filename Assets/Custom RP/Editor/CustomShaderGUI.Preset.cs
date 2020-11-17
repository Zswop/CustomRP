//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public partial class CustomShaderGUI : ShaderGUI
    {
        bool Clipping
        {
            set => SetProperty("_Clipping", "_CLIPPING", value);
        }
        bool PremultiplyAlpha
        {
            set => SetProperty("_PremulAlpha", "_PREMULTIPLY_ALPHA", value);
        }
        BlendMode SrcBlend
        {
            set => SetProperty("_SrcBlend", (float)value);
        }
        BlendMode DstBlend
        {
            set => SetProperty("_DstBlend", (float)value);
        }
        bool ZWrite
        {
            set => SetProperty("_ZWrite", value ? 1f : 0f);
        }

        enum ShadowMode
        {
            On, Clip, Dither, Off
        }

        ShadowMode Shadows
        {
            set
            {
                if (SetProperty("_Shadows", (float)value))
                {
                    SetKeyword("_SHADOWS_CLIP", value == ShadowMode.Clip);
                    SetKeyword("_SHADOWS_DITHER", value == ShadowMode.Dither);
                }
            }
        }

        RenderQueue RenderQueue
        {
            set
            {
                foreach (Material m in materials)
                {
                    m.renderQueue = (int)value;
                }
            }
        }

        bool PresetButton(string name)
        {
            if (GUILayout.Button(name))
            {
                editor.RegisterPropertyChangeUndo(name);
                return true;
            }
            return false;
        }

        void OpaquePreset()
        {
            if (PresetButton("Opaque"))
            {
                Clipping = false;
                Shadows = ShadowMode.On;
                PremultiplyAlpha = false;
                SrcBlend = BlendMode.One;
                DstBlend = BlendMode.Zero;
                ZWrite = true;
                RenderQueue = RenderQueue.Geometry;
            }
        }

        void ClipPreset()
        {
            if (PresetButton("Clip"))
            {
                Clipping = true;
                Shadows = ShadowMode.Clip;
                PremultiplyAlpha = false;
                SrcBlend = BlendMode.One;
                DstBlend = BlendMode.Zero;
                ZWrite = true;
                RenderQueue = RenderQueue.AlphaTest;
            }
        }

        void FadePreset()
        {
            if (PresetButton("Fade"))
            {
                Clipping = false;
                Shadows = ShadowMode.Dither;
                PremultiplyAlpha = false;
                SrcBlend = BlendMode.SrcAlpha;
                DstBlend = BlendMode.OneMinusSrcAlpha;
                ZWrite = false;
                RenderQueue = RenderQueue.Transparent;
            }
        }

        void TransparentPreset()
        {
            if (PresetButton("Transparent"))
            {
                Clipping = false;
                Shadows = ShadowMode.Dither;
                PremultiplyAlpha = true;
                SrcBlend = BlendMode.One;
                DstBlend = BlendMode.OneMinusSrcAlpha;
                ZWrite = false;
                RenderQueue = RenderQueue.Transparent;
            }
        }

        bool showPresets = false;

        void DrawPresets()
        {
            EditorGUILayout.Space();
            showPresets = EditorGUILayout.Foldout(showPresets, "Presets", true);
            if (showPresets)
            {
                OpaquePreset();
                ClipPreset();
                FadePreset();
                if (HasPremultiplyAlpha && PresetButton("Transparent")) {
                    TransparentPreset();
                }
            }
        }
    }
}
