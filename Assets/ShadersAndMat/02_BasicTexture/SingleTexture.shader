Shader "02_BasicTexture/Single Texture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) = 20
    }
    SubShader
    {
        Pass {
            Tags { "RenderType"="Opaque" }
            LOD 200
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include"Lighting.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            //在Unity中，我们需要使用纹理名_ST的方式来声明某个纹理的属性。其中，ST是缩放（scale）和平移（translation）的缩写
            //_MainTex_ST.xy存储的是缩放值，而_MainTex_ST.zw存储的是偏移值。
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                //顶点shader计算出来的发现向量
                fixed3 worldNormal : TEXCOORD0;
                fixed3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                return o;
            }
            fixed4 frag(v2f i) : SV_Target {
                
                fixed3 worldNormal = i.worldNormal;
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                // 获取环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormal,worldLightDir));
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);


                fixed3 color = ambient + diffuse + specular;
                return fixed4(color,1.0);
            }
            ENDCG
        }
        
    }
    FallBack "Specular"
}
