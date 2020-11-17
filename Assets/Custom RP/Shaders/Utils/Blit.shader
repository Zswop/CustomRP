Shader "Hidden/CustomRP/Blit"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "CustomPipeline"}
        LOD 100

        Pass
        {
            Name "Blit"

            Cull Off
		    ZTest Always
		    ZWrite Off
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

            #include "../../ShaderLibrary/Common.hlsl"

            struct Varyings {
	            float4 positionCS : SV_POSITION;
	            float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BlitTex);
            SAMPLER(sampler_BlitTex);

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

            half4 frag(Varyings input) : SV_TARGET {
               half4 col = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, input.uv);
               return col;
            }

			ENDHLSL
        }
    }
}