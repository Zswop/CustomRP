//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
    public class PlanarReflection : MonoBehaviour
    {
        public float clipPlaneOffset = 0.01f;

        // Given position/normal of the plane, calculates plane in camera space.
        Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
        {
            Vector3 offsetPos = pos + normal * clipPlaneOffset;
            Matrix4x4 m = cam.worldToCameraMatrix;
            Vector3 cpos = m.MultiplyPoint(offsetPos);
            Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
            return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
        }

        // Adjusts the given projection matrix so that near plane is the given clipPlane
        // clipPlane is given in camera space. See article in Game Programming Gems 5.
        // http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
        static Matrix4x4 CalculateObliqueMatrix(Matrix4x4 projection, Vector4 clipPlane)
        {
            Vector4 q = projection.inverse * new Vector4(
                Sgn(clipPlane.x),
                Sgn(clipPlane.y),
                1.0F,
                1.0F
                );
            Vector4 c = clipPlane * (2.0F / (Vector4.Dot(clipPlane, q)));
            // third row = clip plane - fourth row
            projection[2] = c.x - projection[3];
            projection[6] = c.y - projection[7];
            projection[10] = c.z - projection[11];
            projection[14] = c.w - projection[15];
            return projection;
        }

        static Matrix4x4 CalculateReflectionMatrix(Vector4 plane /* xyz: normal, w: d */)
        {
            Matrix4x4 reflectionMat = Matrix4x4.zero;

            reflectionMat.m00 = (1.0F - 2.0F * plane[0] * plane[0]);
            reflectionMat.m01 = (-2.0F * plane[0] * plane[1]);
            reflectionMat.m02 = (-2.0F * plane[0] * plane[2]);
            reflectionMat.m03 = (-2.0F * plane[3] * plane[0]);

            reflectionMat.m10 = (-2.0F * plane[1] * plane[0]);
            reflectionMat.m11 = (1.0F - 2.0F * plane[1] * plane[1]);
            reflectionMat.m12 = (-2.0F * plane[1] * plane[2]);
            reflectionMat.m13 = (-2.0F * plane[3] * plane[1]);

            reflectionMat.m20 = (-2.0F * plane[2] * plane[0]);
            reflectionMat.m21 = (-2.0F * plane[2] * plane[1]);
            reflectionMat.m22 = (1.0F - 2.0F * plane[2] * plane[2]);
            reflectionMat.m23 = (-2.0F * plane[3] * plane[2]);

            reflectionMat.m30 = 0.0F;
            reflectionMat.m31 = 0.0F;
            reflectionMat.m32 = 0.0F;
            reflectionMat.m33 = 1.0F;

            return reflectionMat;
        }

        // Extended sign: returns -1, 0 or 1 based on sign of a
        static float Sgn(float a)
        {
            if (a > 0.0F) { return 1.0F; }
            if (a < 0.0F) { return -1.0F; }
            return 0.0F;
        }
    }
}