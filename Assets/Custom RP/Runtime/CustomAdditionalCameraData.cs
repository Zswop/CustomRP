//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEngine.Rendering;

namespace OpenCS
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Camera))]
    [ImageEffectAllowedInSceneView]
    public class CustomAdditinalCameraData : MonoBehaviour
    {
        [SerializeField] public bool postProcessing = false;

        [RenderingLayerMaskField]
        [SerializeField] public int renderingLayerMask = -1;

        [SerializeField] public bool requireDepthTexture;
        [SerializeField] public bool requireOpaqueTexture;

        [SerializeField] public bool renderShadows;
    }
}