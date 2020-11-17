//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
    [ExecuteAlways]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class SurfaceCreator : MonoBehaviour
    {
        private Mesh mesh;
        private int currentResolution;

        private Vector3[] vertices;
        private int[] triangles;
        private Vector2[] uv;
        private Vector3[] normals;
        private Color[] colors;

        [Range(1, 200)]
        public int resolution;

        public Vector3 offset;

        public Vector3 rotation;

        public float frequency = 1f;

        [Range(1, 8)]
        public int octaves = 1;

        [Range(1f, 4f)]
        public float lacunarity = 2f;

        [Range(0f, 1f)]
        public float persistence = 0.5f;

        [Range(1, 3)]
        public int dimensions = 3;

        public NoiseMethodType type;

        public Gradient coloring;

        public bool damping;

        [Range(0f, 1f)]
        public float strength = 1f;

        public bool coloringForStrength;

        public bool analyticalDerivatives;

        void OnEnable()
        {
            CreateMesh();
            Refresh();
        }

        void OnValidate()
        {
            if (mesh != null)
            {
                Refresh();
            }
        }

        private void Refresh()
        {
            if (currentResolution != resolution)
            {
                FillMesh();
            }

            Quaternion q = Quaternion.Euler(rotation);
            Quaternion qInv = Quaternion.Inverse(q);
            Vector3 point00 = q * new Vector3(-0.5f, -0.5f) + offset;
            Vector3 point10 = q * new Vector3(0.5f, -0.5f) + offset;
            Vector3 point01 = q * new Vector3(-0.5f, 0.5f) + offset;
            Vector3 point11 = q * new Vector3(0.5f, 0.5f) + offset;

            NoiseMethod method = Noise.noiseMethods[(int)type][dimensions - 1];
            float amplitude = damping ? strength / frequency : strength;

            float stepSize = 1f / resolution;
            for (int v = 0, y = 0; y <= resolution; y++)
            {
                Vector3 point0 = Vector3.Lerp(point00, point01, y * stepSize);
                Vector3 point1 = Vector3.Lerp(point10, point11, y * stepSize);
                for (int x = 0; x <= resolution; x++, v++)
                {
                    Vector3 point = Vector3.Lerp(point0, point1, x * stepSize);
                    NoiseSample sample = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
                    sample = type == NoiseMethodType.Value ? (sample - 0.5f) : (sample * 0.5f); //[-0.5f, 0.5f]

                    if (coloringForStrength)
                    {
                        colors[v] = coloring.Evaluate(sample.value + 0.5f);
                        sample *= amplitude;
                    }
                    else
                    {
                        sample *= amplitude;
                        colors[v] = coloring.Evaluate(sample.value + 0.5f);
                    }
                    vertices[v].y = sample.value;

                    sample.derivative = qInv * sample.derivative;
                    if (analyticalDerivatives)
                    {
                        normals[v] = new Vector3(-sample.derivative.x, 1f, -sample.derivative.y).normalized;
                    }
                }
            }

            mesh.colors = colors;
            mesh.vertices = vertices;
            //mesh.RecalculateNormals();
            if (!analyticalDerivatives) { 
                CalculateNormals();
            }
            mesh.normals = normals;
        }

        private void CalculateNormals()
        {
            for (int v = 0, z = 0; z <= resolution; z++)
            {
                for (int x = 0; x <= resolution; x++, v++)
                {
                    //Vector3 tagent = new Vector3(1.0f, GetXDerivative(x, z), 0f);
                    //Vector3 binormal = new Vector3(0f, GetZDerivative(x, z), 1.0f);
                    //Vector3 normal = Vector3.Cross(binormal, tagent);

                    //normals[v] = new Vector3(-GetXDerivative(x, z), 1.0f, 0);
                    //normals[v] = new Vector3(0f, 1.0f, -GetZDerivative(x, z));
                    //normals[v] = normal;

                    normals[v] = new Vector3(-GetXDerivative(x, z), 1.0f, -GetZDerivative(x, z));
                    normals[v].Normalize();
                }
            }
        }

        private float GetXDerivative(int x, int z)
        {
            float left, right, scale;
            int rowOffset = z * (resolution + 1);

            int leftOffset = 0, rightOffset = 0;
            if (x > 0) { leftOffset = -1; }
            if (x < resolution) { rightOffset = 1; }

            left = vertices[rowOffset + x + leftOffset].y;
            right = vertices[rowOffset + x + rightOffset].y;
            scale = resolution * 1.0f / (rightOffset - leftOffset);
            return (right - left) * scale;
        }

        private float GetZDerivative(int x, int z)
        {
            float back, forward, scale;
            int rowLength = resolution + 1;
            int backOffset = 0, forwardOffset = 0;
            if (z > 0) { backOffset = -1; }
            if (z < resolution) { forwardOffset = 1; }

            back = vertices[(z + backOffset) * rowLength + x].y;
            forward = vertices[(z + forwardOffset) * rowLength + x].y;
            scale = resolution * 1.0f / (forwardOffset - backOffset);
            return (back - forward) * scale;
        }

        private void FillMesh()
        {
            currentResolution = resolution;
            mesh.Clear();

            vertices = new Vector3[(resolution + 1) * (resolution + 1)];
            triangles = new int[resolution * resolution * 6];
            uv = new Vector2[vertices.Length];
            normals = new Vector3[vertices.Length];
            colors = new Color[vertices.Length];

            float stepSize = 1f / resolution;
            for (int z = 0, v = 0; z <= resolution; ++z)
            {
                for (int x = 0; x <= resolution; ++x, ++v)
                {
                    vertices[v] = new Vector3(x * stepSize - 0.5f, 0f, z * stepSize - 0.5f);
                    uv[v] = new Vector2(x * stepSize, z * stepSize);
                    normals[v] = Vector3.up;
                    colors[v] = Color.black;
                }
            }
            for (int z = 0, v = 0, t = 0; z < resolution; ++z, ++v)
            {
                for (int x = 0; x < resolution; ++x, ++v, t+=6)
                {
                    triangles[t] = v;
                    triangles[t + 1] = v + resolution + 1;
                    triangles[t + 2] = v + 1;
                    triangles[t + 3] = v + 1;
                    triangles[t + 4] = v + resolution + 1;
                    triangles[t + 5] = v + resolution + 2;
                }
            }

            mesh.vertices = vertices;
            mesh.triangles = triangles;
            mesh.normals = normals;
            mesh.uv = uv;
            mesh.colors = colors;
        }

        private void CreateMesh()
        {
            if (mesh == null)
            {
                mesh = new Mesh();
                mesh.name = "Surface";
                GetComponent<MeshFilter>().mesh = mesh;
            }
        }

        public bool showNormals;

        private void OnDrawGizmosSelected()
        {
            if (showNormals && vertices != null)
            {
                float scale = 1f / resolution;
                Gizmos.color = Color.yellow;
                for (int v = 0; v < vertices.Length; v++)
                {
                    Gizmos.DrawRay(vertices[v], normals[v] * scale);
                }
            }
        }
    }
}