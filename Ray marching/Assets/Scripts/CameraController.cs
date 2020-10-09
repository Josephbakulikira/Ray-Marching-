using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CameraController : SceneViewFilter
{
    private Material r_material;
    public float r_maxDistance;
    public Vector3 r_modInterval;
    public Vector4 r_sphere;
    public Vector4 r_box;
    public Vector4 r_sphere2;
    public float r_boxSphereSmooth;
    public float r_boxRound;
    public float r_sphereIntersectSmooth;

    public Transform r_light;
    public Color r_color;
    [SerializeField]

    private Shader r_shader;

    public Material raymarchingMaterial
    {
        get
        {
            if (!r_material && r_shader)
            {
                r_material = new Material(r_shader);
                r_material.hideFlags = HideFlags.HideAndDontSave;
            }
            return r_material;
        }
    }

    private Camera r_camera;
    public Camera raymarchingCamera {
        get { 
            if (!r_camera) {
                r_camera = GetComponent<Camera>();
            }
            return r_camera;
        }
    }
    
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!raymarchingMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        raymarchingMaterial.SetVector("r_light", r_light ? r_light.forward : Vector3.down);
        raymarchingMaterial.SetMatrix("r_cameraFrustum", cameraFrustum(raymarchingCamera));
        raymarchingMaterial.SetMatrix("r_cameraToWorld", raymarchingCamera.cameraToWorldMatrix);
        raymarchingMaterial.SetFloat("r_maxdistance", r_maxDistance);
        raymarchingMaterial.SetVector("r_modInterval", r_modInterval);
        raymarchingMaterial.SetVector("r_sphere", r_sphere);
        raymarchingMaterial.SetVector("r_box", r_box);
        raymarchingMaterial.SetVector("r_sphere2", r_sphere2);
        raymarchingMaterial.SetFloat("r_boxRound", r_boxRound);
        raymarchingMaterial.SetFloat("r_boxSphereSmooth", r_boxSphereSmooth);
        raymarchingMaterial.SetFloat("r_sphereIntersectSmooth", r_sphereIntersectSmooth);
        raymarchingMaterial.SetColor("r_mainColor", r_color);

        RenderTexture.active = destination;

        raymarchingMaterial.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();
        raymarchingMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        //bottom left
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        //bottom right
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //top right
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        // top left
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 cameraFrustum(Camera camera)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fieldOfView = Mathf.Tan((camera.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 r_UP = Vector3.up * fieldOfView;
        Vector3 r_RIGHT = Vector3.right * fieldOfView * camera.aspect;
        Vector3 r_BOTTOMLEFT = (-Vector3.forward - r_RIGHT - r_UP);
        Vector3 r_BOTTOMRIGHT = (-Vector3.forward + r_RIGHT - r_UP);
        Vector3 r_TOPLEFT = (-Vector3.forward - r_RIGHT + r_UP);
        Vector3 r_TOPRIGHT = (-Vector3.forward + r_RIGHT + r_UP);

        frustum.SetRow(3, r_BOTTOMLEFT);
        frustum.SetRow(2, r_BOTTOMRIGHT);
        frustum.SetRow(1, r_TOPRIGHT);
        frustum.SetRow(0, r_TOPLEFT);
       

        return frustum;
    }
}
