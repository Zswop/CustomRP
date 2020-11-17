#ifndef CUSTOM_FXAA_INCLUDED
#define CUSTOM_FXAA_INCLUDED

#if defined(LOW_QUALITY)
	#define EDGE_STEP_COUNT 4
	#define EDGE_STEPS 1, 1.5, 2, 4
	#define EDGE_GUESS 12
#else
	#define EDGE_STEP_COUNT 10
	#define EDGE_STEPS 1, 1.5, 2, 2, 2, 2, 2, 2, 2, 4
	#define EDGE_GUESS 8
#endif

static const float edgeSteps[EDGE_STEP_COUNT] = { EDGE_STEPS };

float4 _ContrastThreshold;

#define CONSTRAST_THRESH _ContrastThreshold.x
#define RELATIVE_THRESH _ContrastThreshold.y
#define SUBPIEXL_BLENDING _ContrastThreshold.z

//#define FXAA_SAMPLE_LUMINANCE(uv)
//#define FXAA_SAMPLE_SOURCE(uv)
//#define FXAA_SOURCE_SIZE

struct LuminanceData {
	float m, n, e, s, w;
	float ne, nw, se, sw;
	float h, l, contrast;
};

LuminanceData SampleLuminanceNeighborhood (float2 uv) {
	LuminanceData l;
	float2 texelSize = FXAA_SOURCE_SIZE.xy;
	l.m = FXAA_SAMPLE_LUMINANCE(uv);
	l.n = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(0, 1));
	l.e = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(1, 0));
	l.s = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(0, -1));
	l.w = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(-1, 0));

	l.ne = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(1, 1));
	l.nw = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(-1, 1));
	l.se = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(1, -1));
	l.sw = FXAA_SAMPLE_LUMINANCE(uv + texelSize * float2(-1, -1));

	l.h = max(max(max(max(l.m, l.n), l.e), l.s), l.w);
	l.l = min(min(min(min(l.m, l.n), l.e), l.s), l.w);
	l.contrast = l.h - l.l;
	return l;
}

bool ShouldSkipPixel(LuminanceData l){
	float threshold = max(CONSTRAST_THRESH, RELATIVE_THRESH * l.h);
	if (l.contrast < threshold) {
		return true;
	}
	return false;
}

float DeterminePixelBlendFactor(LuminanceData l){
	float filter = 2 * (l.n + l.e + l.s + l.w) + (l.ne + l.nw + l.se + l.sw);
	filter *= 1.0 / 12;

	float blend = abs(filter - l.m) / l.contrast;
	blend = smoothstep(0, 1, blend);
	return blend * blend * SUBPIEXL_BLENDING;
}

struct EdgeData{
	bool isHorizontal;
	float2 step;
	float gradient, luminance;
};

EdgeData DetermineEdge (LuminanceData l){
	EdgeData e;

	float horizontal = 2 * abs(l.n + l.s - 2 * l.m) + abs(l.ne + l.se - 2 * l.e) + abs (l.nw + l.sw  - 2 * l.w);
	float vertical = 2 * abs(l.e + l.w - 2 * l.m) + abs(l.ne + l.nw - 2 * l.n) + abs(l.se + l.sw - 2 * l.s);
	e.isHorizontal = horizontal >= vertical;

	float4 texelSize = FXAA_SOURCE_SIZE;
	e.step = e.isHorizontal ? float2(0, texelSize.y) : float2(texelSize.x, 0);

	float pluminance = e.isHorizontal ? l.n : l.e;
	float nluminance = e.isHorizontal ? l.s : l.w;
	float pgradient = abs(pluminance - l.m);
	float ngradient = abs(nluminance - l.m);

	if (pgradient < ngradient){
		e.step = -e.step;
		e.gradient = ngradient;
		e.luminance = nluminance;
	}
	else{
		e.gradient = pgradient;
		e.luminance = pluminance;
	}
	return e;
}

float DetermineEdgeBlendFactor (LuminanceData l, EdgeData e, float2 uv) {
	float2 uvEdge = uv + e.step * 0.5;

	float2 edgeStep = 0;
	float4 texelSize = FXAA_SOURCE_SIZE;
	if (e.isHorizontal){ edgeStep = float2(texelSize.x, 0); }
	else{ edgeStep = float2(0, texelSize.y); }
	
	float edgeLuminance = (l.m + e.luminance) * 0.5;
	float gradientThreshold = e.gradient * 0.25;

	bool pAtEnd = false;
	float2 puv = uvEdge;
	float pLuminanceDelta = 0;

	UNITY_UNROLL
	for (int i = 0; i < EDGE_STEP_COUNT && !pAtEnd; i++){
		puv += edgeStep * edgeSteps[i];
		pLuminanceDelta = FXAA_SAMPLE_LUMINANCE(puv) - edgeLuminance;
		pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
	}

	if (!pAtEnd){ 
		puv += edgeStep * EDGE_GUESS; 
	}
	//return pAtEnd;

	bool nAtEnd = false;
	float2 nuv = uvEdge;
	float nLuminanceDelta = 0;

	UNITY_UNROLL
	for (int j = 0; j < EDGE_STEP_COUNT && !nAtEnd; j++){
		nuv -= edgeStep * edgeSteps[j];
		nLuminanceDelta = FXAA_SAMPLE_LUMINANCE(nuv) - edgeLuminance;
		nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
	}

	if (!nAtEnd){
		nuv -= edgeStep * EDGE_GUESS;
	}
	//return nAtEnd;

	float pDistance, nDistance;
	if (e.isHorizontal) {
		pDistance = puv.x - uv.x;
		nDistance = uv.x - nuv.x;
	}
	else {
		pDistance = puv.y - uv.y;
		nDistance = uv.y - nuv.y;
	}

	bool deltaSign;
	float shortestDistance;	
	if (pDistance <= nDistance) {
		shortestDistance = pDistance;
		deltaSign = pLuminanceDelta >= 0;
	}
	else {
		shortestDistance = nDistance;
		deltaSign = nLuminanceDelta >= 0;
	}
	if (deltaSign == (l.m - edgeLuminance >= 0)) {
		return 0;
	}
	//return shortestDistance * 10;
	return 0.5 - shortestDistance / (pDistance + nDistance);
}

half4 ApplyFXAA(float2 uv) {
	LuminanceData l = SampleLuminanceNeighborhood(uv);
	if (ShouldSkipPixel(l)) {
		//return half4(0, 0, 0, 0);
		return FXAA_SAMPLE_SOURCE(uv);
	}
	//return l.contrast;

	float pixelBlend = DeterminePixelBlendFactor(l);
	//return blend;

	EdgeData e = DetermineEdge(l);
	//return e.isHorizontal ? float4(1, 0, 0, 0) : 1;
	//if (e.isHorizontal){ return e.step.y < 0 ? float4(1, 0, 0, 0) : 1;}
	//else { return e.step.x < 0 ? float4(1, 0, 0, 0) : 1; }

	float edgeBlend = DetermineEdgeBlendFactor(l, e, uv);
	//return edgeBlend - pixelBlend;

	float finalBlend = max(pixelBlend, edgeBlend);
	half4 color = FXAA_SAMPLE_SOURCE(uv + e.step * finalBlend);
	return color;
}

#endif