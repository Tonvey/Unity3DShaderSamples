Shader "02_BasicTexture/Normal Map Tengent Space"
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
                //顶点shader计算出来的发现向量
                fixed4 uv : TEXCOORD0;
                fixed3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                //计算副法线
                //float3 binormal=cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
                //构造一个矩阵能够让向量从object space 到 tangent space
                //float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);
                //或者直接使用内置宏
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }
            fixed4 frag(v2f i) : SV_Target {

                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                fixed3 tangentNormal;
                //If the texture is not marked as "Normalmap" 
                //tangentNormal.xy=(packedNormal.xy*21)*_BumpScale;
                //tangentNormal.z=sqrt(1.0- saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                //Or mark the texture as "Normalmap", and use the built-in funciton
                tangentNormal=UnpackNormal(packedNormal);
                tangentNormal.xy*=_BumpScale;
                tangentNormal.z=sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                fixed3 albedo=tex2D(_MainTex,i.uv).rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(tangentNormal,tangentLightDir));

                fixed3 halfDir=normalize(tangentLightDir+tangentViewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(tangentNormal,halfDir)),_Gloss);
                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
        
    }
    FallBack "Specular"
}
