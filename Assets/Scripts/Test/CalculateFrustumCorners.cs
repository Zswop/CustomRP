using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CalculateFrustumCorners : MonoBehaviour
{
    Vector3[] frustumCorners;

    private void OnEnable()
    {
        frustumCorners = new Vector3[4];
        var camera = GetComponent<Camera>();
        camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), camera.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, frustumCorners);
        Debug.LogFormat("Camera frustumCorners: {0}, {1}, {2}, {3}", 
            frustumCorners[0], frustumCorners[1], frustumCorners[2], frustumCorners[3]);        

        for (int i = 0; i < 4; i++)
        {
            var worldSpaceCorner = camera.transform.TransformPoint(frustumCorners[i]);
            Debug.LogFormat("Camera frustumCorners: {0}, {1}", frustumCorners[i], worldSpaceCorner);
        }
    }

    void Update()
    {
        var camera = GetComponent<Camera>();
        camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), camera.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, frustumCorners);

        for (int i = 0; i < 4; i++)
        {
            var worldSpaceCorner = camera.transform.TransformVector(frustumCorners[i]);
            Debug.DrawRay(camera.transform.position, worldSpaceCorner, Color.blue);
        }

        camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), camera.farClipPlane, Camera.MonoOrStereoscopicEye.Left, frustumCorners);

        for (int i = 0; i < 4; i++)
        {
            var worldSpaceCorner = camera.transform.TransformVector(frustumCorners[i]);
            Debug.DrawRay(camera.transform.position, worldSpaceCorner, Color.green);
        }

        camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), camera.farClipPlane, Camera.MonoOrStereoscopicEye.Right, frustumCorners);

        for (int i = 0; i < 4; i++)
        {
            var worldSpaceCorner = camera.transform.TransformVector(frustumCorners[i]);
            Debug.DrawRay(camera.transform.position, worldSpaceCorner, Color.red);
        }
    }
}