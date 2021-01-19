#ifndef CUSTOM_MESH_HAIR_LIGHTING_INCLUDED
#define CUSTOM_MESH_HAIR_LIGHTING_INCLUDED

half3 ShiftTangent(half3 tangent, half3 normal, half shift) {
	half3 shiftT = tangent + normal * shift;
	return SafeNormalize(shiftT);
}

half StrandSpecular(half3 tangent, half3 viewDirection, half3 lightDir, half exponent) {
	half3 h = SafeNormalize(viewDirection + lightDir);
	half th = dot(tangent, h);

	half sinth = sqrt(1 - th * th);
	half dirAtten = smoothstep(-1.0, 0.0, th);
	return dirAtten * pow(sinth, exponent);
}

half3 MeshHairDiffuse(half3 diffuseColor, Light light, float3 normal, float3 viewDirection) {	
	half clampNoL = saturate(dot(normal, light.direction));
	half3 diffuse = lerp(_DiffuseDarkColor.rgb, half3(1.0, 1.0, 1.0), clampNoL);
	return (diffuse * diffuseColor * light.attenuation) * light.color;
}

half3 MeshHairSpecualr(half3 diffuseColor, Light light, half3 tangent, 
	half3 normal, half3 viewDirection, half specShift, half specMask) {
	//shfit tangents
	half3 t1 = ShiftTangent(tangent, normal, _PrimaryShift + specShift);
	half3 t2 = ShiftTangent(tangent, normal, _SecondaryShift + specShift);

	//sepcular lighting	
	half3 lightDir = light.direction;
	half s1 = StrandSpecular(t1, viewDirection, lightDir, _PrimaryPower);
	half s2 = StrandSpecular(t2, viewDirection, lightDir, _SecondaryPower);
	half3 specular = _PrimaryColor.rgb * s1 * _PrimaryIntensity;
	specular += _SecondaryColor.rgb * specMask * s2 * _SecondaryIntensity;
	return specular * diffuseColor * light.color * light.attenuation;
}

#endif