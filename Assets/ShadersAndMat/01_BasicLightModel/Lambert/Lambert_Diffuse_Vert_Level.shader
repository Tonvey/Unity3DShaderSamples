Shader "01_LightModel/Lambert Diffuse Vertex Level"
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
                //输入的顶点坐标
                float4 vertex : POSITION;
                //输入的法线
                float3 normal : NORMAL;
            };
            struct v2f {
                //输出的视口坐标位置
                float4 pos : SV_POSITION;
                //顶点shader计算出来的顶点颜色
                fixed3 color : COLOR;
            };

            //声明跟properties 同名同类型的变量表名当前程序中要引用的property,unity会自动负责赋值
            fixed3 _Diffuse;
            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 获取环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                o.color = ambient + diffuse;
                return o;
            }
            fixed4 frag(v2f i) : SV_Target {
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
