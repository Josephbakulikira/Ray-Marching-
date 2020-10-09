Shader "Auctux/RayMarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            uniform float4x4 r_cameraFrustum, r_cameraToWorld;
            uniform float4 r_sphere;
            uniform float3 r_light;
            uniform float r_maxdistance;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {   
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                // ray direction
                float3 ray: TEXCOORD1;
                
            };

            v2f vert (appdata v)
            {
                
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ray = r_cameraFrustum[(int)index].xyz;
                o.ray /= abs(o.ray.z);
                o.ray = mul(r_cameraToWorld, o.ray);
                return o;
            }
            float r_Sphere(float3 r_position, float r_radius) {
                return length(r_position) - r_radius;
            }
            float r_distanceField(float3 r_position) {
                float r_sampleSphere = r_Sphere(r_position - r_sphere.xyz, r_sphere.w);
                return r_sampleSphere;
            }

            float3 getNormal(float3 p) {
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(
                    r_distanceField(p + offset.xyy) - r_distanceField(p - offset.xyy),
                    r_distanceField(p + offset.yxy) - r_distanceField(p - offset.yxy),
                    r_distanceField(p + offset.yyx) - r_distanceField(p - offset.yyx)
                    );
                return normalize(n);
                    
            }

            fixed4 raymarching( float3 r_origin, float3 r_direction) {
                fixed4 result = fixed4(1, 1, 1, 1);
                float ray_dist = 0;
                const int max_iteration = 164;
                for (int i = 0; i < max_iteration; i++)
                {
                    if (ray_dist > r_maxdistance) {
                        result = fixed4(r_direction, 1);
                        break;
                    }
                    float3 pos = r_origin + r_direction * ray_dist;
                    //collision check
                    float r_dist = r_distanceField(pos);
                    if (r_dist < 0.01) {
                        //collide == True
                        float3 n = getNormal(pos);
                        float light = dot(-r_light, n);
                        result = fixed4(1, 1, 1, 1) * light;
                        break;
                    }
                    ray_dist += r_dist;

                }
                return result;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 ray_direction = normalize(i.ray.xyz);
                float3 ray_origin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(ray_origin, ray_direction);
                return result;
            }
            ENDCG
        }
    }
}
