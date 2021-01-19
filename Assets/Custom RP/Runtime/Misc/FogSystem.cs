//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
    [ExecuteInEditMode]
    public class FogSystem : MonoBehaviour
    {
        [Header("FogSystem")]
        public bool EnableFog = true;

        [Range(0, 1.0f)]
        public float FogThickness = 1;

        [Header("DistanceFog")]
        public Color DistanceFogColor = new Color(0.1f, 0.8f, 0.9f);
        public float DistanceFogStart = 20;
        public float DistanceFogEnd = 300;

        [Header("HighFog")]
        public Color HeightFogColor = new Color(0.1f, 0.1f, 0.95f);
        [Range(0, 1.0f)]
        public float HeightFogThickness = 1;

        public float HeightFogBaseHeight = 0;
        [Range(0, 0.3f)]
        public float HeightFogHeighFalloff = 0.1f;
        [Range(0, 1.0f)]
        public float HeightFogDistanceFalloff = 0.1f;

        private void OnEnable()
        {
            Reflesh();
        }

        private void OnValidate()
        {
            Reflesh();
        }

        private void OnDisable()
        {
            SetKeyword(false);
        }

        private void OnDestroy()
        {
            SetKeyword(false);
        }

        private void Reflesh()
        {
            SetKeyword(EnableFog);

            if (EnableFog)
            {
                Shader.SetGlobalFloat(ShaderPropertyId.FogThickness, FogThickness);

                Vector4 distanceFogParams = Vector4.zero;
                float distance = Mathf.Max(0.000001f, DistanceFogEnd - DistanceFogStart);
                distanceFogParams.z = 1 / distance;
                distanceFogParams.w = -DistanceFogStart / distance;
                Shader.SetGlobalVector(ShaderPropertyId.DistanceFogParams, distanceFogParams);
                Shader.SetGlobalColor(ShaderPropertyId.DistanceFogColor, DistanceFogColor);

                Vector4 heightFogParams = Vector4.zero;
                heightFogParams.x = HeightFogThickness;
                heightFogParams.y = HeightFogHeighFalloff;
                heightFogParams.z = HeightFogBaseHeight;
                heightFogParams.w = HeightFogDistanceFalloff;
                Shader.SetGlobalColor(ShaderPropertyId.HeightFogParams, heightFogParams);
                Shader.SetGlobalColor(ShaderPropertyId.HeightFogColor, HeightFogColor);
            }
        }

        void SetKeyword(bool enabled)
        {
            if (enabled)
            {
                Shader.EnableKeyword("CUSTOM_FOG");
            }
            else
            {
                Shader.DisableKeyword("CUSTOM_FOG");
            }
        }

        private static class ShaderPropertyId
        {
            public static int FogThickness = Shader.PropertyToID("_FogThickness");

            public static int DistanceFogColor = Shader.PropertyToID("_DistanceFogColor");
            public static int DistanceFogParams = Shader.PropertyToID("_DistanceFogParams");

            public static int HeightFogColor = Shader.PropertyToID("_HeightFogColor");
            public static int HeightFogParams = Shader.PropertyToID("_HeightFogParams");
        }
    }
}