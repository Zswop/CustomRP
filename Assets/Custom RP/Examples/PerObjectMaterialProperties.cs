using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour {

	static int baseColorId = Shader.PropertyToID("_BaseColor");
	static int cutoffId = Shader.PropertyToID("_Cutoff");
    static int metallicId = Shader.PropertyToID("_Metallic");
    static int smoothnessId = Shader.PropertyToID("_Smoothness");    
    static int emissionColorId = Shader.PropertyToID("_EmissionColor");

	static MaterialPropertyBlock block;

	[SerializeField]
	Color baseColor = Color.white;

	[SerializeField, Range(0f, 1f)]
	float alphaCutoff = 0.5f, metallic = 0.0f, smoothness = 0.5f;

    [SerializeField, ColorUsage(false, true)]
    Color emissionColor = Color.black;

    void Awake () {
		OnValidate();
	}

	void OnValidate () {
		if (block == null) {
			block = new MaterialPropertyBlock();
		}
		block.SetColor(baseColorId, baseColor);
		block.SetFloat(cutoffId, alphaCutoff);
        block.SetFloat(metallicId, metallic);
        block.SetFloat(smoothnessId, smoothness);
        block.SetColor(emissionColorId, emissionColor);
        GetComponent<Renderer>().SetPropertyBlock(block);
	}
}