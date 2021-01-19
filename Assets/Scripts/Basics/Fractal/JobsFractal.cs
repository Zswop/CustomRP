//#define UNITY_JOBS

//Writing by Jiayun Li
//Copyright (c) 2020

#if UNITY_JOBS

using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;

using static Unity.Mathematics.math;
using quaternion = Unity.Mathematics.quaternion;

public class JobsFractal : MonoBehaviour
{
    static readonly int matricesId = Shader.PropertyToID("_Matrices");

    static float3[] directions =
    {
        up(), right(), left(), forward(), back()
    };

    static quaternion[] rotations =
    {
        quaternion.identity,
        quaternion.RotateZ(-0.5f * PI), quaternion.RotateZ(0.5f * PI),
        quaternion.RotateX(0.5f * PI), quaternion.RotateX(-0.5f * PI)
    };


    [SerializeField, Range(1, 8)]
    int depth = 4;

    [SerializeField]
    Mesh mesh = default;

    [SerializeField]
    Material material = default;

    static MaterialPropertyBlock propertyBlock;

    private NativeArray<FractalPart>[] fractalParts;
    private NativeArray<float3x4>[] matrices;
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
        fractalParts = new NativeArray<FractalPart>[depth];
        matrices = new NativeArray<float3x4>[depth];
        matricesBuffers = new ComputeBuffer[depth];
        for (int i = 0, length = 1; i < depth; i++, length *= 5)
        {
            fractalParts[i] = new NativeArray<FractalPart>(length, Allocator.Persistent);
            matrices[i] = new NativeArray<float3x4>(length, Allocator.Persistent);
            matricesBuffers[i] = new ComputeBuffer(length, 12 * 4);
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

        material.EnableKeyword("_MATRIX_3X4");
        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();
        }
    }

    void OnDisable()
    {
        material.DisableKeyword("_MATRIX_3X4");
        for (int i = 0; i < matricesBuffers.Length; ++i)
        {
            matricesBuffers[i].Release();
            fractalParts[i].Dispose();
            matrices[i].Dispose();
        }
        matricesBuffers = null;
        matrices = null;
        fractalParts = null;
    }

    void Update()
    {
        float deltaSpinAngle = 0.125f * PI * Time.deltaTime;

        float objectScale = transform.lossyScale.x;
        float scale = objectScale;
        var rootPart = fractalParts[0][0];
        rootPart.spinAngle += deltaSpinAngle;
        rootPart.worldRotation = mul(transform.rotation,
            mul(rootPart.rotation, quaternion.RotateY(rootPart.spinAngle))
        );
        rootPart.worldPosition = transform.position;
        fractalParts[0][0] = rootPart;
        float3x3 r = float3x3(rootPart.worldRotation) * objectScale;
        matrices[0][0] = float3x4(r.c0, r.c1, r.c2, rootPart.worldPosition);

        JobHandle jobHandle = default;
        for (int li = 1; li < fractalParts.Length; li++)
        {
            scale *= 0.5f;
            jobHandle = new UpdateFractalLevelJob
            {
                spinAngleDelta = deltaSpinAngle,
                scale = scale,
                parents = fractalParts[li - 1],
                parts = fractalParts[li],
                matrices = matrices[li],
            }.ScheduleParallel(fractalParts[li].Length, 5, jobHandle);
        }
        jobHandle.Complete();

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

    [BurstCompile(FloatPrecision.Standard, FloatMode.Fast, CompileSynchronously = true)]
    struct UpdateFractalLevelJob : IJobFor
    {
        public float spinAngleDelta;
        public float scale;

        [ReadOnly]
        public NativeArray<FractalPart> parents;

        public NativeArray<FractalPart> parts;

        [WriteOnly]
        public NativeArray<float3x4> matrices;

        public void Execute(int i)
        {
            FractalPart parent = parents[i / 5];
            FractalPart part = parts[i];
            part.spinAngle += spinAngleDelta;
            part.worldRotation = mul(parent.worldRotation,
                mul(part.rotation, quaternion.RotateY(part.spinAngle))
            );
            part.worldPosition = parent.worldPosition +
                mul(parent.worldRotation, (1.5f * scale * part.direction)
            );
            parts[i] = part;

            float3x3 r = float3x3(part.worldRotation) * scale;
            matrices[i] = float3x4(r.c0, r.c1, r.c2, part.worldPosition);
        }
    }

    struct FractalPart
    {
        public float3 direction, worldPosition;
        public quaternion rotation, worldRotation;
        public float spinAngle;
    }
}
#endif