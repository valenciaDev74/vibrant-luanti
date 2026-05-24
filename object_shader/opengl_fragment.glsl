VARYING_ vec4 varColor;
VARYING_ vec3 vNormal;
VARYING_ vec3 worldPosition;
VARYING_ float nightRatio;

uniform highp vec3 cameraOffset;
uniform vec3 cameraPosition;

#if USE_ARRAY_TEXTURE
uniform sampler2DArray baseTexture;
VARYING_ vec3 varTexCoord;
#else
uniform sampler2D baseTexture;
VARYING_ vec2 varTexCoord;
#endif

#ifdef ENABLE_DYNAMIC_SHADOWS
uniform sampler2D ShadowMapSampler;
uniform vec3 v_LightDirection;
uniform float f_textureresolution;
uniform mat4 m_ShadowViewProj;
uniform float f_shadowfar;
uniform float f_shadow_strength;
uniform vec4 CameraPos;
uniform float xyPerspectiveBias0;
uniform float xyPerspectiveBias1;
uniform vec3 shadow_tint;
uniform vec3 dayLight;

VARYING_ float adj_shadow_strength;
VARYING_ float cosLight;
VARYING_ float f_normal_length;
VARYING_ vec3 shadow_position;
VARYING_ float perspective_factor;

#if __VERSION__ >= 130
#define mtsmoothstep smoothstep
#else
float mtsmoothstep(in float edge0, in float edge1, in float x)
{
	float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}
#endif

float shadowCutoff(float x) {
#if defined(ENABLE_TRANSLUCENT_FOLIAGE) && MATERIAL_TYPE == TILE_MATERIAL_WAVING_LEAVES
	return mtsmoothstep(0.0, 0.002, x);
#else
	return step(0.0, x);
#endif
}

vec3 getLightSpacePosition()
{
	return shadow_position * 0.5 + 0.5;
}

float getHardShadow(sampler2D shadowsampler, vec2 smTexCoord, float realDistance)
{
	float texDepth = texture2D(shadowsampler, smTexCoord.xy).r;
	float visibility = shadowCutoff(realDistance - texDepth);
	return visibility;
}

#define PCFBOUND 1.0
#define PCFSAMPLES 9

float getShadow(sampler2D shadowsampler, vec2 smTexCoord, float realDistance)
{
	return getHardShadow(shadowsampler, smTexCoord.xy, realDistance);
}
#endif

void main(void)
{
	vec4 texColor = texture(baseTexture, varTexCoord);

	if (texColor.a < 0.1) {
		discard;
	}

	vec4 finalColor = texColor * varColor;

#ifdef ENABLE_DYNAMIC_SHADOWS
	if (f_shadow_strength > 0.0) {
		float shadow_int = 0.0;
		vec3 posLightSpace = getLightSpacePosition();

		float distance_rate = (1.0 - pow(clamp(2.0 * length(posLightSpace.xy - 0.5), 0.0, 1.0), 10.0));
		if (max(abs(posLightSpace.x - 0.5), abs(posLightSpace.y - 0.5)) > 0.5)
			distance_rate = 0.0;
		float f_adj_shadow_strength = max(adj_shadow_strength - mtsmoothstep(0.9, 1.1, posLightSpace.z), 0.0);

		if (distance_rate > 1e-7) {
			if (cosLight > 0.0 || f_normal_length < 1e-3)
				shadow_int = getShadow(ShadowMapSampler, posLightSpace.xy, posLightSpace.z);
			else
				shadow_int = 1.0;
			shadow_int *= distance_rate;
			shadow_int = clamp(shadow_int, 0.0, 1.0);
		}

		float adjusted_night_ratio = pow(max(0.0, nightRatio), 0.6);

		float shadow_uncorrected = shadow_int;

		const float self_shadow_cutoff_cosine = 0.035;
		if (f_normal_length != 0.0 && cosLight < self_shadow_cutoff_cosine) {
			shadow_int = max(shadow_int, 1.0 - clamp(cosLight, 0.0, self_shadow_cutoff_cosine) / self_shadow_cutoff_cosine);

#if (MATERIAL_TYPE == TILE_MATERIAL_WAVING_LEAVES || MATERIAL_TYPE == TILE_MATERIAL_WAVING_PLANTS)
			shadow_uncorrected = mix(shadow_int, shadow_uncorrected, clamp(distance_rate * 4.0 - 3.0, 0.0, 1.0));
#endif
		}

		shadow_int *= f_adj_shadow_strength;

		vec3 shadow_tint = vec3(0.02, 0.06, 0.92);
		vec3 night_ambient = vec3(0.1059, 0.1490, 0.2314);

		vec3 day_part = finalColor.rgb * (1.0 - shadow_int * (1.0 - shadow_tint));

		float brightness = max(finalColor.r, max(finalColor.g, finalColor.b));
		float darkness = 1.0 - smoothstep(0.0, 0.05, brightness);
		float ambientWeight = clamp(brightness / 0.05, 0.0, 1.0);
		vec3 night_part = mix(finalColor.rgb, night_ambient, darkness * ambientWeight * ambientWeight);

		finalColor.rgb =
			adjusted_night_ratio * night_part +
			(1.0 - adjusted_night_ratio) * day_part;

		vec3 viewVec = normalize(worldPosition + cameraOffset - cameraPosition);

#if (MATERIAL_TYPE == TILE_MATERIAL_WAVING_PLANTS || MATERIAL_TYPE == TILE_MATERIAL_WAVING_LEAVES) && defined(ENABLE_TRANSLUCENT_FOLIAGE)
		finalColor.rgb += 4.0 * dayLight * texColor.rgb * normalize(texColor.rgb * varColor.rgb * varColor.rgb)
			* f_adj_shadow_strength * pow(max(-dot(v_LightDirection, viewVec), 0.0), 4.0)
			* max(1.0 - shadow_uncorrected, 0.0);
#endif
	}
#endif

	finalColor.a = texColor.a;
	gl_FragData[0] = finalColor;
}
