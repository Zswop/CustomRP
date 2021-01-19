Shader "Hidden/CustomRP/Blit"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "CustomPipeline"}
        LOD 100

        HLSLINCLUDE
        #include "../../ShaderLibrary/Common.hlsl"

        struct Varyings {
	        float4 positionCS : SV_POSITION;
	        float2 uv : TEXCOORD0;
        };

        Varyings vert(uint vertexID : SV_VertexID) {
	        Varyings output;

	        float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
	        output.positionCS = float4(uv * 2.0 - 1.0, 0.0, 1.0);
	        output.uv = uv;
	        if (_ProjectionParams.x < 0.0) {
		        output.uv.y = 1.0 - output.uv.y;
	        }
	        return output;
        }
        ENDHLSL

        Pass
        {
            Name "Blit Color"

            Cull Off
		    ZTest Always
		    ZWrite Off
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag
            
            TEXTURE2D(_BlitTex);
            SAMPLER(sampler_BlitTex);

            half4 frag(Varyings input) : SV_TARGET {
               half4 col = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, input.uv);
               return col;
            }
			ENDHLSL
        }

        Pass
        {
            Name "Blit Depth"

            Cull Off
		    ZTest Always
            ColorMask 0
            ZWrite On
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

            TEXTURE2D_FLOAT(_BlitTex);
            SAMPLER(sampler_BlitTex);

            float frag(Varyings input) : SV_DEPTH  {
               float depth = SAMPLE_DEPTH_TEXTURE(_BlitTex, sampler_BlitTex, input.uv);
               return depth;
            }
			ENDHLSL
        }
    }
}