using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestScript : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Vector3 x = new Vector3(1.0f, 0.0f, 0.0f);
        Vector3 y = new Vector3(0.0f, 1.0f, 0.0f);
        Vector3 z = new Vector3(0.0f, 0.0f, 1.0f);

        Vector3 xcy = UnityEngine.Vector3.Cross(x, y);       // right: z
        Vector3 ycz = UnityEngine.Vector3.Cross(y, z);       // right: x
        Vector3 zcx = UnityEngine.Vector3.Cross(z, x);       // right: y

        Debug.Log("xcy: " + xcy.ToString("F4"));
        Debug.Log("ycz: " + ycz.ToString("F4"));
        Debug.Log("zcx: " + zcx.ToString("F4"));
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
