using UnityEngine;
using UnityEngine.Rendering;

public class MeshBall : MonoBehaviour {

	static int baseColorId = Shader.PropertyToID("_BaseColor");
    static int metallicId = Shader.PropertyToID("_Metallic");
    static int smoothnessId = Shader.PropertyToID("_Smoothness");

    [SerializeField]
	Mesh mesh = default;

	[SerializeField]
	Material material = default;
	
	Matrix4x4[] matrices = new Matrix4x4[1022];
	Vector4[] baseColors = new Vector4[1022];
    float[] metallic = new float[1022];
    float[] smoothness = new float[1022];

    MaterialPropertyBlock block;

	void Awake ()
    {
		for (int i = 0; i < matrices.Length; i++) {
			matrices[i] = Matrix4x4.TRS(
				Random.insideUnitSphere * 10f,
				Quaternion.Euler(
					Random.value * 360f, Random.value * 360f, Random.value * 360f
				),
				Vector3.one * Random.Range(0.5f, 1.5f)
			);
			baseColors[i] =
				new Vector4(
					Random.value, Random.value, Random.value,
					Random.Range(0.5f, 1f)
				);
            metallic[i] = Random.value < 0.25f ? 1f : 0f;
            smoothness[i] = Random.Range(0.05f, 0.95f);
        }
	}

	void Update ()
    {
		if (block == null) {
			block = new MaterialPropertyBlock();
			block.SetVectorArray(baseColorId, baseColors);
            block.SetFloatArray(metallicId, metallic);
            block.SetFloatArray(smoothnessId, smoothness);

            var positions = new Vector3[1022];
            var occlusionProbes = new Vector4[1022];
            for (int i = 0; i < matrices.Length; i++){
                positions[i] = matrices[i].GetColumn(3);
            }
            var lightProbes = new SphericalHarmonicsL2[1022];
            LightProbes.CalculateInterpolatedLightAndOcclusionProbes(
                positions, lightProbes, occlusionProbes
                );
            block.CopySHCoefficientArraysFrom(lightProbes);
            block.CopyProbeOcclusionArrayFrom(occlusionProbes);
        }
		Graphics.DrawMeshInstanced(mesh, 0, material, matrices, 1022, block,
            ShadowCastingMode.On, true, 0, null, LightProbeUsage.CustomProvided);
	}
}