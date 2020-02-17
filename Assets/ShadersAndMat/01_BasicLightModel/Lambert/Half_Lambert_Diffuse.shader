Shader "01_LightModel/Half Lambert Diffuse Pixel Level"
{
    Properties
    {
        _Diffuse("Color" ,Color) = (1,1,1,1)
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
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                //顶点shader计算出来的发现向量
                fixed3 worldNormal : TEXCOORD0;
            };

            //声明跟properties 同名同类型的变量表名当前程序中要引用的property,unity会自动负责赋值
            fixed3 _Diffuse;
            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                return o;
            }
            fixed4 frag(v2f i) : SV_Target {
                
                // 获取环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = i.worldNormal;
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * ( 0.5  * dot(worldNormal,worldLightDir)+0.5);
                fixed3 color = ambient + diffuse;
                return fixed4(color,1.0);
            }
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
