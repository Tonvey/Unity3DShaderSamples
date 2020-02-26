Shader "04_HighLevelTexture/Reflect"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _ReflectColor ("Reflect Color", Color) = (1,1,1,1)
        _ReflectAmount ("Reflect Amount", Range(0,1)) = 1
        _Cubemap("Reflect Cubemap",Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        Pass {
            Tags { "LightMode"="ForwardBase" }
            //ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            LOD 200
            
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members worldRefl)
#pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            #include"Lighting.cginc"
            #include"AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            float _ReflectAmount;
            samplerCUBE _Cubemap;
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //和法线方向normal不同，tangent的类型是float4，而非float3，这是因为我们需要使用tangent.w分量来决定切线空间中的第三个坐标轴——副切线的方向性。 
                float4 texcoord : TEXCOORD0;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                //之所以使用TEXCOORD0是因为要用到插值寄存器,从顶点着色器传出的参数会在片段着色器中进行插值
                fixed3 worldNormal : TEXCOORD0;
                fixed3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl :TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);
                TRANSFER_SHADOW(o);
                return o;
                
            }
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*_Color.rgb;
                fixed3 diffuse=_LightColor0.rgb*_Color.rgb*max(0,dot(worldNormal,worldLightDir));
                fixed3 reflection = texCUBE(_Cubemap,i.worldRefl).rgb * _ReflectColor.rgb;
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 color = ambient + lerp(diffuse,reflection,_ReflectAmount)*atten;

                return fixed4(color,1.0);
            }
            ENDCG
        }
        
    }
    FallBack "Transparent/Cutout/VertexLit"

}
