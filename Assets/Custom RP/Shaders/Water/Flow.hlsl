#ifndef CUSTOM_FLOW_INCLUDED
#define CUSTOM_FLOW_INCLUDED

float3 FlowUVW(float2 uv, float2 flowVector, float2 jump, float flowOffset,
	float tiling, float time, bool flowB) {
	float phaseOffset = flowB ? 0.5 : 0;
	float progress = frac(time + phaseOffset);

	float3 uvw;
	uvw.xy = uv - flowVector * (progress + flowOffset);
	uvw.xy *= tiling;
	uvw.xy += phaseOffset;

	uvw.xy += (time - progress) * jump;
	uvw.z = 1 - abs(1  - 2 * progress);
	return uvw;
}

float2 DirectionalFlowUV(float2 uv, float2 flowVector, float flowSpeed, float tiling, float time,
	out float2x2 rotation){
	float2 dir = normalize(flowVector.xy);
	rotation = float2x2(dir.y, dir.x, -dir.x, dir.y);
	uv = mul(float2x2(dir.y, -dir.x, dir.x, dir.y), uv);
	uv.y -= time * flowSpeed;
	return uv * tiling;
}

struct WaveData {
	float3 position;
	float3 tangent;
	float3 bitangent;
};

float3 GerstnerWave (float2 wavedirection, float steepness, float wavelength, float3 p,
	inout float3 tangent, inout float3 bitangent) {
	float k = 2 * PI / wavelength;
	float c = sqrt(9.8 / k);
	float2 d = normalize(wavedirection);
	float f = k * (dot(d, p.xz) - c * _Time.y);
	float a = steepness / k;
	tangent += float3(
		-d.x * d.x * (steepness * sin(f)),
		d.x * (steepness * cos(f)),
		-d.x * d.y * (steepness * sin(f))
	);
	bitangent += float3(
		-d.x * d.y * (steepness * sin(f)),
		d.y * (steepness * cos(f)),
		-d.y * d.y * (steepness * sin(f))
	);
	return float3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
	);
}

WaveData GetGerstnerWave (float4 waveA, float4 waveB, float4 waveC, float3 gridPoint) {
	WaveData waveData;
	float3 tangent = float3(1, 0, 0);
	float3 bitangent = float3(0, 0, 1);

	float3 position = gridPoint;
	position += GerstnerWave(waveA.xy, waveA.z, waveA.w, gridPoint, tangent, bitangent);
	position += GerstnerWave(waveB.xy, waveB.z, waveB.w, gridPoint, tangent, bitangent);
	position += GerstnerWave(waveC.xy, waveC.z, waveC.w, gridPoint, tangent, bitangent);

	waveData.position = position;
	waveData.tangent = tangent;
	waveData.bitangent = bitangent;
	return waveData;
}

#endif