//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

[RequireComponent(typeof(Camera))]
public class OrbitCamera : MonoBehaviour
{
    [SerializeField]
    Transform focus = default;

    [SerializeField, Range(1f, 20f)]
    float distance = 5f;

    [SerializeField, Min(0f)]
    float focusRadius = 1f;

    [SerializeField, Range(0f, 1f)]
    float focusCentering = 0.75f;

    [SerializeField, Range(1f, 360f)]
    float rotationSpeed = 90f;

    [SerializeField, Range(-89f, 89f)]
    float minVerticalAngle = -30f, maxVerticalAngle = 60f;

    [SerializeField, Min(0f)]
    float alignDelay = 5f;

    [SerializeField, Range(0f, 90f)]
    float alignSmoothRange = 45f;

    Vector2 orbitAngles = new Vector2(45f, 0f);

    Vector3 focusPoint, previousFocusPoint;

    float alignDelayTimer;

    Camera regularCamera;

    Vector3 CameraHalfExtends
    {
        get
        {
            Vector3 halfExtends;
            halfExtends.y = regularCamera.nearClipPlane * 
                Mathf.Tan(0.5f * Mathf.Deg2Rad * regularCamera.fieldOfView);
            halfExtends.x = halfExtends.y * regularCamera.aspect;
            halfExtends.z = 0f;
            return halfExtends;
        }
    }

    void OnValidate()
    {
        if (minVerticalAngle > maxVerticalAngle)
        {
            maxVerticalAngle = minVerticalAngle;
        }
    }

    void Awake()
    {
        focusPoint = focus.position;
        regularCamera = GetComponent<Camera>();
    }

    void LateUpdate()
    {
        float deltaTime = Time.unscaledDeltaTime;

        UpdateFocusPoint(deltaTime);
        if (ManualRotation(deltaTime) || AutomaticRotation(deltaTime)){
            ConstrainAngles();
        }

        Quaternion lookRotation = Quaternion.Euler(orbitAngles);
        Vector3 lookDirection = lookRotation * Vector3.forward;

        Vector3 lookPosition = focusPoint - lookDirection * distance;
        Vector3 rectOffset = lookDirection * regularCamera.nearClipPlane;
        Vector3 rectPosition = lookPosition + rectOffset;
        Vector3 castFrom = focus.position;
        Vector3 castLine = rectPosition - castFrom;
        float castDistance = castLine.magnitude;
        Vector3 castDirection = castLine / castDistance;

        if (Physics.BoxCast(
            castFrom, CameraHalfExtends, castDirection, out RaycastHit hit,
            lookRotation, castDistance))
        {
            rectPosition = castFrom + castDirection * hit.distance;
            lookPosition = rectPosition - rectOffset;
        }

        transform.SetPositionAndRotation(lookPosition, lookRotation);
    }

    void UpdateFocusPoint(float deltaTime)
    {
        previousFocusPoint = focusPoint;
        Vector3 targetPoint = focus.position;
        float distance = Vector3.Distance(targetPoint, focusPoint);
        if (distance > focusRadius){
            focusPoint = Vector3.Lerp(targetPoint, focusPoint, focusRadius / distance);
        }

        if (distance > 0.01f && focusCentering > 0f)
        {
            float lerp01 = Mathf.Pow(1f - focusCentering, deltaTime);
            focusPoint = Vector3.Lerp(targetPoint, focusPoint, lerp01);
        }
    }

    bool ManualRotation(float deltaTime)
    {
        Vector2 input = new Vector2(
            Input.GetAxis("Vertical Camera"),
            Input.GetAxis("Horizontal Camera")
        );

        const float e = 0.001f;
        if (input.x < -e || input.x > e || input.y < -e || input.y > e)
        {
            orbitAngles += rotationSpeed * deltaTime * input;
            alignDelayTimer = 0;
            return true;
        }
        alignDelayTimer += deltaTime;
        return false;
    }

    bool AutomaticRotation(float deltaTime)
    {
        if (alignDelayTimer < alignDelay){
            return false;
        }

        Vector2 movement = new Vector2(
            focusPoint.x - previousFocusPoint.x,
            focusPoint.z - previousFocusPoint.z
        );
        float movementDeltaSqr = movement.sqrMagnitude;
        if (movementDeltaSqr < 0.000001f){
            return false;
        }

        float headingAngle = GetAngleY(movement / Mathf.Sqrt(movementDeltaSqr));
        float deltaAbs = Mathf.Abs(Mathf.DeltaAngle(orbitAngles.y, headingAngle));
        float rotationChange = rotationSpeed * Mathf.Min(deltaTime, movementDeltaSqr);
        if (deltaAbs < alignSmoothRange){
            rotationChange *= deltaAbs / alignSmoothRange;
        }
        else if (180f - deltaAbs < alignSmoothRange){
            rotationChange *= (180f - deltaAbs) / alignSmoothRange;
        }

        orbitAngles.y = Mathf.MoveTowardsAngle(orbitAngles.y, headingAngle, rotationChange);
        return true;
    }

    void ConstrainAngles()
    {
        orbitAngles.x = Mathf.Clamp(orbitAngles.x, minVerticalAngle, maxVerticalAngle);
        if (orbitAngles.y < 0f) {  orbitAngles.y += 360f; }
        else if (orbitAngles.y >= 360f){ orbitAngles.y -= 360f; }
    }

    static float GetAngleY(Vector2 direction)
    {
        float angle = Mathf.Acos(direction.y) * Mathf.Rad2Deg;
        return direction.x < 0f ? 360f - angle : angle;
    }
}