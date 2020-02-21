// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "02_BasicTexture/Normal Map World Space"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        // bump 是Unity内置的法线纹理,当没有提供任何法线纹理时,就对应了默认值
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // bumpscale 用于控制凹凸程度
        _BumpScale ("Bump Scale", Float) = 1.0
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
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                //和法线方向normal不同，tangent的类型是float4，而非float3，这是因为我们需要使用tangent.w分量来决定切线空间中的第三个坐标轴——副切线的方向性。 
                float4 texcoord : TEXCOORD0;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                //之所以使用TEXCOORD0是因为要用到插值寄存器,从顶点着色器传出的参数会在片段着色器中进行插值
                fixed4 uv : TEXCOORD0;
                fixed4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;
                //计算从顶点坐标切换转换到世界坐标的矩阵
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z); 
                return o;
                
            }
            fixed4 frag(v2f i) : SV_Target {
                float3 worldPos = float3(
                    i.TtoW0.w,
                    i.TtoW1.w,
                    i.TtoW2.w);
                float3 worldNormal = float3(
                    i.TtoW0.z,
                    i.TtoW1.z,
                    i.TtoW2.z);
                fixed3 lightDir =  normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir =  normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0-saturate(dot(bump.xy,bump.xy)));
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));

                fixed3 albedo=tex2D(_MainTex,i.uv).rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(bump,lightDir));

                fixed3 halfDir=normalize(lightDir+viewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(bump,halfDir)),_Gloss);
                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
        
    }
    FallBack "Specular"
}
