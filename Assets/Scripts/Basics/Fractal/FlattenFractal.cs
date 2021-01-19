//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

public class FlattenFractal : MonoBehaviour
{
    [SerializeField, Range(1, 8)]
    int depth = 2;

    [SerializeField]
    Mesh mesh = default;

    [SerializeField]
    Material material = default;

    static Vector3[] directions = 
    {
        Vector3.up, Vector3.right, Vector3.left, Vector3.forward, Vector3.back
    };

    static Quaternion[] rotations = 
    {
        Quaternion.identity,
        Quaternion.Euler(0f, 0f, -90f), Quaternion.Euler(0f, 0f, 90f),
        Quaternion.Euler(90f, 0f, 0f), Quaternion.Euler(-90f, 0f, 0f)
    };

    private FractalPart[][] fractalParts;

    void Awake()
    {
        fractalParts = new FractalPart[depth][];
        for (int i = 0, length = 1; i < depth; i++, length *= 5)
        {
            fractalParts[i] = new FractalPart[length];
        }

        float scale = 1.0f;
        fractalParts[0][0] = CreateFractalPart(0, 0, scale);
        for (int li = 1; li < depth; ++li)
        {
            scale *= 0.5f;
            var levelParts = fractalParts[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi += 5)
            {
                for (int j = 0; j < 5; ++j)
                {
                    levelParts[fpi + j] = CreateFractalPart(li, j, scale);
                }
            }
        }
    }

    void Update()
    {
        var deltaRotation = Quaternion.Euler(new Vector3(0.0f, 22.5f * Time.deltaTime, 0.0f));

        var rootPart = fractalParts[0][0];
        rootPart.ratation *= deltaRotation;
        rootPart.transform.localRotation = rootPart.ratation;
        fractalParts[0][0] = rootPart;
        for (int li = 1; li < fractalParts.Length; li++)
        {
            FractalPart[] parentParts = fractalParts[li - 1];
            FractalPart[] levelParts = fractalParts[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi++)
            {
                Transform parentTran = parentParts[fpi / 5].transform;
                FractalPart part = levelParts[fpi];

                part.ratation *= deltaRotation;
                part.transform.localRotation = parentTran.localRotation * part.ratation;
                part.transform.localPosition = parentTran.localPosition +
                   parentTran.localRotation * (1.5f * part.transform.localScale.x * part.direction);
                levelParts[fpi] = part;
            }
        }
    }

    FractalPart CreateFractalPart(int levelIndex, int childIndex, float scale)
    {
        var go = new GameObject("Fractal Part " + levelIndex + " C" + childIndex);
        go.transform.SetParent(transform, false);
        go.transform.localScale = Vector3.one * scale;

        go.AddComponent<MeshFilter>().mesh = mesh;
        go.AddComponent<MeshRenderer>().material = material;

        return new FractalPart()
        {
            direction = directions[childIndex],
            ratation = rotations[childIndex],
            transform = go.transform,
        };
    }

    struct FractalPart
    {
        public Vector3 direction;
        public Quaternion ratation;
        public Transform transform;
    }
}