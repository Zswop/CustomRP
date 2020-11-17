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
        [SerializeField] bool postProcessing = false;

        public bool PostProcessing 
        { 
            get { return postProcessing; }
            set { postProcessing = value; }
        }
    }
}