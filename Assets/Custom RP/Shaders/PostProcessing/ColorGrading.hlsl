#ifndef CUSTOM_COLORGRADING_INCLUDED
#define CUSTOM_COLORGRADING_INCLUDED

float4 _ColorAdjustments;
float4 _ColorFilter;
float4 _WhiteBalance;
float4 _SplitToningShadows;
float4 _SplitToningHighlights;
float4 _ChannelMixerRed;
float4 _ChannelMixerGreen;
float4 _ChannelMixerBlue;
float4 _SMHShadows;
float4 _SMHMidTones;
float4 _SMHHighLights;
float4 _SMHRange;

float GetLuminance(float3 color, bool useACES) {
	if (useACES){ return AcesLuminance(color); }
	else { return Luminance(color); }
}

float3 ColorGradePostExposure (float3 color) {
	return color * _ColorAdjustments.x;
}

float3 ColorGradeWhiteBalance (float3 color) {
	float3 colorLMS = LinearToLMS(color);
	colorLMS *= _WhiteBalance.rgb;
	return LMSToLinear(colorLMS);
}

float3 ColorGradingContrast (float3 color, bool useACES) {
	if (useACES) {  color = ACES_to_ACEScc(unity_to_ACES(color)); }
	else { color = LinearToLogC(color); }
	color = (color - ACEScc_MIDGRAY) * _ColorAdjustments.y + ACEScc_MIDGRAY;
	if (useACES) { color = ACES_to_ACEScg(ACEScc_to_ACES(color)); }
	else { color = LogCToLinear(color);}
	return color;
}

float3 ColorGradeColorFilter (float3 color) {
	return color * _ColorFilter.rgb;
}

float3 ColorGradeHueShift(float3 color) {
	color = RgbToHsv(color);
	float hue = color.x + _ColorAdjustments.z;
	color.x = RotateHue(hue, 0.0, 1.0);
	return HsvToRgb(color);
}

float3 ColorGradingSaturation(float3 color, bool useACES) {
	float luminance = GetLuminance(color, useACES);
	return (color - luminance) * _ColorAdjustments.w + luminance;
}

float3 ColorGradeSplitToning(float3 color, bool useACES) {
	float3 colorGamma = PositivePow(color, 1.0 / 2.2);
	float t = saturate(GetLuminance(saturate(colorGamma), useACES) + _SplitToningShadows.w);
	float3 shadows = lerp(0.5, _SplitToningShadows.rgb, 1.0 - t);
	float3 highlights = lerp(0.5, _SplitToningHighlights.rgb, t);
	colorGamma = SoftLight(colorGamma, shadows);
	colorGamma = SoftLight(colorGamma, highlights);
	return PositivePow(colorGamma, 2.2);
}

float3 ColorGradingChannelMixer(float3 color) {
	return mul(float3x3(_ChannelMixerRed.rgb, _ChannelMixerGreen.rgb, _ChannelMixerBlue.rgb), color);
}

float3 ColorGradingShadowsMidtonesHighlights(float3 color, bool useACES) {
	float luminance = GetLuminance(color, useACES);
	float shadowWeight = 1 - smoothstep(_SMHRange.x, _SMHRange.y, luminance);
	float highlightsWeight = smoothstep(_SMHRange.z, _SMHRange.w, luminance);
	float midtonesWeight = 1 - shadowWeight - highlightsWeight;
	return color * _SMHShadows.rgb * shadowWeight + 
		color * _SMHMidTones.rgb * midtonesWeight + 
		color * _SMHHighLights.rgb * highlightsWeight;
}

float3 ColorGrade (float3 color, bool useACES) {
	color = ColorGradePostExposure(color);
	color = ColorGradeWhiteBalance(color);
	color = ColorGradingContrast(color, useACES);

	color = ColorGradeColorFilter(color);
	color = max(color, 0.0);
	color = ColorGradeSplitToning(color, useACES);
	color = ColorGradingChannelMixer(color);
	color = max(color, 0.0);
	color = ColorGradingShadowsMidtonesHighlights(color, useACES);
	color = ColorGradeHueShift(color);
	color = ColorGradingSaturation(color, useACES);
	color = max(color, 0.0);
	return color;
}

#endif