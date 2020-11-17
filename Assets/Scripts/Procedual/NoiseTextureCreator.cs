//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
    [ExecuteAlways]
    [RequireComponent(typeof(MeshRenderer))]
    public class NoiseTextureCreator : MonoBehaviour
    {
        private Texture2D texture;

        [Range(2, 512)]
        public int resolution = 256;
        
        public float frequency = 1.0f;

        [Range(1, 8)]
        public int octaves = 1;

        [Range(1f, 4f)]
        public float lacunarity = 2f;

        [Range(0f, 1f)]
        public float persistence = 0.5f;

        [Range(1, 3)]
        public int dimensions = 3;

        public Gradient coloring;

        public NoiseMethodType type = NoiseMethodType.Value;

        private void OnValidate()
        {
            FillTexture();
        }

        private void OnEnable()
        {
            FillTexture();
        }

        private void CreateTexture()
        {
            if (texture == null)
            {
                texture = new Texture2D(resolution, resolution, TextureFormat.RGB24, true);
                texture.name = "Procedure_" + resolution;
                texture.wrapMode = TextureWrapMode.Clamp;
                texture.filterMode = FilterMode.Trilinear;
                texture.anisoLevel = 9;

                //GetComponent<MeshRenderer>().sharedMaterial.mainTexture = texture;
                GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_BaseMap", texture);
            }
        }
        
        private void FillTexture()
        {
            CreateTexture();

            if (texture.width != resolution)
            {
                texture.Resize(resolution, resolution);
            }

            Vector3 point00 = new Vector3(-0.5f, -0.5f);
            Vector3 point10 = new Vector3(0.5f, -0.5f);
            Vector3 point01 = new Vector3(-0.5f, 0.5f);
            Vector3 point11 = new Vector3(0.5f, 0.5f);

            NoiseMethod method = Noise.noiseMethods[(int)type][dimensions - 1];

            float stepSize = 1f / resolution;
            for (int y = 0; y < resolution; y++)
            {
                Vector3 point0 = Vector3.Lerp(point00, point01, (y + 0.5f) * stepSize);
                Vector3 point1 = Vector3.Lerp(point10, point11, (y + 0.5f) * stepSize);
                for (int x = 0; x < resolution; x++)
                {
                    Vector3 point = Vector3.Lerp(point0, point1, (x + 0.5f) * stepSize);
                    float sample = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence).value;
                    if (type != NoiseMethodType.Value)
                    {
                        sample = sample * 0.5f + 0.5f;
                    }
                    texture.SetPixel(x, y, coloring.Evaluate(sample));
                }
            }
            texture.Apply();
        }
    }
}