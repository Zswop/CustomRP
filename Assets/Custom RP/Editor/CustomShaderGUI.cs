//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    public partial class CustomShaderGUI : ShaderGUI
    {
        MaterialEditor editor;
        Object[] materials;
        MaterialProperty[] properties;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();
            base.OnGUI(materialEditor, properties);

            this.editor = materialEditor;
            this.materials = materialEditor.targets;
            this.properties = properties;

            BakedEmission();
            DrawPresets();
            if (EditorGUI.EndChangeCheck())
            {
                SetShadowCasterPass();
                CopyLightMappingProperties();
            }
        }

        bool HasProperty(string name) => FindProperty(name, properties, false) != null;

        bool HasPremultiplyAlpha => HasProperty("_PremulAlpha");

        bool SetProperty(string name, float value)
        {
            MaterialProperty property = FindProperty(name, properties, false);
            if (property != null)
            {
                property.floatValue = value;
                return true;
            }
            return false;
        }

        void SetKeyword(string keyword, bool enabled)
        {
            if (enabled)
            {
                foreach (Material m in materials)
                {
                    m.EnableKeyword(keyword);
                }
            }
            else
            {
                foreach (Material m in materials)
                {
                    m.DisableKeyword(keyword);
                }
            }
        }

        void SetProperty(string name, string keyword, bool value)
        {
            if (SetProperty(name, value ? 1f : 0f))
            {
                SetKeyword(keyword, value);
            }
        }

        void BakedEmission()
        {
            EditorGUI.BeginChangeCheck();
            editor.LightmapEmissionProperty();
            if (EditorGUI.EndChangeCheck())
            {
                foreach (Material m in editor.targets)
                {
                    m.globalIlluminationFlags &=
                        ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                }
            }
        }

        void SetShadowCasterPass()
        {
            MaterialProperty shadows = FindProperty("_Shadows", properties, false);
            if (shadows == null || shadows.hasMixedValue)
            {
                return;
            }
            bool enabled = shadows.floatValue < (float)ShadowMode.Off;
            foreach (Material m in materials)
            {
                m.SetShaderPassEnabled("ShadowCaster", enabled);
            }
        }

        void CopyLightMappingProperties()
        {
            MaterialProperty mainTex = FindProperty("_MainTex", properties, false);
            MaterialProperty baseMap = FindProperty("_BaseMap", properties, false);
            if (mainTex != null && baseMap != null)
            {
                mainTex.textureValue = baseMap.textureValue;
                mainTex.textureScaleAndOffset = baseMap.textureScaleAndOffset;
            }
            MaterialProperty color = FindProperty("_Color", properties, false);
            MaterialProperty baseColor = FindProperty("_BaseColor", properties, false);
            if (color != null && baseColor != null)
            {
                color.colorValue = baseColor.colorValue;
            }
        }
    }
}