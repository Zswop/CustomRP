//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

public class ProceduralFractal : MonoBehaviour
{
    static readonly int matricesId = Shader.PropertyToID("_Matrices");

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

    [SerializeField, Range(1, 8)]
    int depth = 2;

    [SerializeField]
    Mesh mesh = default;

    [SerializeField]
    Material material = default;

    static MaterialPropertyBlock propertyBlock;
    private FractalPart[][] fractalParts;
    private Matrix4x4[][] matrices;
    private ComputeBuffer[] matricesBuffers;

    void OnValidate()
    {
        if (fractalParts != null && enabled)
        {
            OnDisable();
            OnEnable();
        }
    }

    void OnEnable()
    {
        fractalParts = new FractalPart[depth][];
        matrices = new Matrix4x4[depth][];
        matricesBuffers = new ComputeBuffer[depth];
        for (int i = 0, length = 1; i < depth; i++, length *= 5)
        {
            fractalParts[i] = new FractalPart[length];
            matrices[i] = new Matrix4x4[length];
            matricesBuffers[i] = new ComputeBuffer(length, 16 * 4);
        }
        
        fractalParts[0][0] = CreateFractalPart(0);
        for (int li = 1; li < depth; ++li)
        {
            var levelParts = fractalParts[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi += 5)
            {
                for (int j = 0; j < 5; ++j)
                {
                    levelParts[fpi + j] = CreateFractalPart(j);
                }
            }
        }

        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();
        }
    }

    void OnDisable()
    {
        for (int i = 0; i< matricesBuffers.Length; ++i)
        {
            matricesBuffers[i].Release();
        }
        matricesBuffers = null;
        matrices = null;
        fractalParts = null;
    }

    void Update()
    {
        float deltaSpinAngle = 22.5f * Time.deltaTime;

        float objectScale = transform.lossyScale.x;
        float scale = objectScale;
        var rootPart = fractalParts[0][0];
        rootPart.spinAngle += deltaSpinAngle;
        rootPart.worldRotation = transform.rotation * 
            (rootPart.rotation * Quaternion.Euler(new Vector3(0.0f, rootPart.spinAngle, 0.0f)));
        rootPart.worldPosition = transform.position;
        fractalParts[0][0] = rootPart;
        matrices[0][0] = Matrix4x4.TRS(
            rootPart.worldPosition, rootPart.worldRotation, Vector3.one * scale);
        for (int li = 1; li < fractalParts.Length; li++)
        {
            scale *= 0.5f;
            FractalPart[] parentParts = fractalParts[li - 1];
            FractalPart[] levelParts = fractalParts[li];
            Matrix4x4[] levelMatrices = matrices[li];
            for (int fpi = 0; fpi < levelParts.Length; fpi++)
            {
                FractalPart parentPart = parentParts[fpi / 5];
                FractalPart part = levelParts[fpi];

                part.spinAngle += deltaSpinAngle;
                part.worldRotation = parentPart.worldRotation * 
                    part.rotation * Quaternion.Euler(new Vector3(0.0f, part.spinAngle, 0.0f));
                part.worldPosition = parentPart.worldPosition +
                   parentPart.worldRotation * (1.5f * scale * part.direction);
                levelParts[fpi] = part;

                levelMatrices[fpi] = Matrix4x4.TRS(
                    part.worldPosition, part.worldRotation, Vector3.one * scale);
            }
        }

        var bounds = new Bounds(rootPart.worldPosition, 3f * objectScale * Vector3.one);
        for (int i = 0; i < matricesBuffers.Length; ++i)
        {
            ComputeBuffer buffer = matricesBuffers[i];
            buffer.SetData(matrices[i]);
            propertyBlock.SetBuffer(matricesId, buffer);
            Graphics.DrawMeshInstancedProcedural(mesh, 0, material, bounds, buffer.count, propertyBlock);
        }
    }

    FractalPart CreateFractalPart(int childIndex)
    {
        return new FractalPart()
        {
            direction = directions[childIndex],
            rotation = rotations[childIndex],
        };
    }

    struct FractalPart
    {
        public Vector3 direction, worldPosition;
        public Quaternion rotation, worldRotation;
        public float spinAngle;
    }
}