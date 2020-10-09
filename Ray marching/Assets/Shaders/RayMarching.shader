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
            #include "DistanceFunctions.cginc"


            sampler2D _MainTex;
            uniform fixed4 r_mainColor;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 r_cameraFrustum, r_cameraToWorld;
            uniform float4 r_box, r_sphere, r_sphere2;
            uniform float r_boxRound, r_boxSphereSmooth, r_sphereIntersectSmooth;
            uniform float3 r_modInterval;
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

            float BoxSphere(float3 p) {
                float Sphere = sdSphere(p - r_sphere.xyz, r_sphere.w);
                float Box = sdRoundBox(p - r_box.xyz, r_box.www, r_boxRound);
                float combine = opSS(Sphere, Box, r_boxSphereSmooth);
                float Sphere2 = sdSphere(p - r_sphere2.xyz, r_sphere2.w);
                float combine2 = opIS(Sphere2, combine, r_sphereIntersectSmooth);
                return combine2;
            }
            float r_distanceField(float3 p) {
                float ground = sdPlane(p, float4(0, 1, 0, 0));
                float BoxSphere1 = BoxSphere(p);
                return opU(ground, BoxSphere1);
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

            fixed4 raymarching( float3 r_origin, float3 r_direction, float this_depth) {
                
                fixed4 result = fixed4(1, 1, 1, 1);
                const int max_iteration = 164;
                float ray_dist = 0;

                for (int i = 0; i < max_iteration; i++)
                {
                    if ( ray_dist > r_maxdistance || ray_dist >= this_depth ) {
                        result = fixed4(r_direction, 0);
                        break;
                    }
                    float3 pos = r_origin + r_direction * ray_dist;
                    //collision check
                    float r_dist = r_distanceField(pos);
                    if (r_dist < 0.01) {
                        //collide == True
                        float3 n = getNormal(pos);
                        float light = dot(-r_light, n);
                        result = fixed4(r_mainColor.rgb* light, 1);
                        break;
                    }
                    ray_dist += r_dist;

                }
                return result;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float r_depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                r_depth *= length(i.ray);
                fixed3 col = tex2D(_MainTex, i.uv);
                float3 ray_direction = normalize(i.ray.xyz);
                float3 ray_origin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(ray_origin, ray_direction, r_depth);
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w , 1.0);
                
            }
            ENDCG
        }
    }
}
