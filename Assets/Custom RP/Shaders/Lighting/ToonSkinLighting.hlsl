#ifndef CUSTOM_TOON_SKIN_LIGHTING_INCLUDED
#define CUSTOM_TOON_SKIN_LIGHTING_INCLUDED

half3 ToonSkinDiffuse(half3 diffuseColor, Light light, half3 normal, half3 viewDirection) {
    half nl = dot(normal, light.direction);
    half wrap = (nl + _TSRollOff) / (1 + _TSRollOff);

    half3 shadowColor = diffuseColor * _TSScatterColor.rgb;
    half scatter = smoothstep(0.0, _TSScatterWidth, wrap * light.attenuation + _TSFlat);
    return lerp(shadowColor, diffuseColor, scatter) * light.attenuation * light.color;
}

#endif