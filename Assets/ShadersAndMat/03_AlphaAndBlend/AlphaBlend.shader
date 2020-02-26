Shader "03_AlphaAndBlend/Alpha Blend"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        // bump 是Unity内置的法线纹理,当没有提供任何法线纹理时,就对应了默认值
        _AlphaScale ("Alpha Scale", Range(0,1)) = 1
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
            #pragma vertex vert
            #pragma fragment frag
            #include"Lighting.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            //在Unity中，我们需要使用纹理名_ST的方式来声明某个纹理的属性。其中，ST是缩放（scale）和平移（translation）的缩写
            //_MainTex_ST.xy存储的是缩放值，而_MainTex_ST.zw存储的是偏移值。
            float4 _MainTex_ST;
            fixed _AlphaScale;
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
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 通过相乘MVP 矩阵,unity会自动升级为以下语句 ,转换顶点到观察空间
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
                
            }
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 albedo=texColor.rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));

                return fixed4(ambient+diffuse,texColor.a*_AlphaScale);
            }
            ENDCG
        }
        
    }
    FallBack "Transparent/Cutout/VertexLit"

}
