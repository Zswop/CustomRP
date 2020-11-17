#ifndef CUSTOM_SAMPLING_INCLUDED
#define CUSTOM_SAMPLING_INCLUDED

float GrainyRand(float2 n)
{
	return sin(dot(n, half2(1233.224, 1743.335)));
}

half4 SampleGrainy(TEXTURE2D_PARAM(tex, samplerTex), float2 uv, float amount, float iteration)
{
    float random = GrainyRand(uv);

    half4 s = 0.0h;
    for (int i = 0; i < iteration; ++i)
    {
        random = frac(43758.5453 * random + 0.61432);
        float offsetx = random * 2 - 1.0h;
        random = frac(43758.5453 * random + 0.61432);
        float offsety = random * 2 - 1.0h;

        s += (SAMPLE_TEXTURE2D(tex, samplerTex, uv + float2(offsetx, offsety) * amount));
    }
    return s / iteration;
}

half4 SampleBokeh(TEXTURE2D_PARAM(tex, samplerTex), float2 uv, float2 texelSize, float radius, float iteration)
{
    const float x = cos(2.39996323f);
    const float y = sin(2.39996323f);

    half r = 1.0;
    half2 angle = half2(0.0, radius);
    half2x2 goldenRot = half2x2(x, y, -y, x);

    half4 w = 0;
    half4 s = 0.0h;
    for (int i = 0; i < iteration; ++i)
    {
        r += 1.0/r;
        angle = mul(goldenRot, angle);
        half4 bokeh = (SAMPLE_TEXTURE2D(tex, samplerTex, uv + texelSize * (r - 1.0) * angle));
        s += bokeh * bokeh;
        w += bokeh;
    }
    return s / w;
}

half4 DownsampleBox4Tap(TEXTURE2D_PARAM(tex, samplerTex), float2 uv, float2 texelSize, float amount)
{
	float4 d = texelSize.xyxy * float4(-amount, -amount, amount, amount);

    half4 s;
    s =  (SAMPLE_TEXTURE2D(tex, samplerTex, uv + d.xy));
    s += (SAMPLE_TEXTURE2D(tex, samplerTex, uv + d.zy));
    s += (SAMPLE_TEXTURE2D(tex, samplerTex, uv + d.xw));
    s += (SAMPLE_TEXTURE2D(tex, samplerTex, uv + d.zw));

    return s * 0.25h;
}

#endif