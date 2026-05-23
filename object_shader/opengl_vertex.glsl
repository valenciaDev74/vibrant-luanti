uniform mat4 mWorld;
uniform vec3 dayLight;
uniform float animationTimer;

VARYING_ vec4 varColor;
VARYING_ vec3 vNormal;
VARYING_ vec3 worldPosition;
VARYING_ float nightRatio;

#if USE_ARRAY_TEXTURE
uniform sampler2DArray baseTexture;
VARYING_ vec3 varTexCoord;
#else
uniform sampler2D baseTexture;
VARYING_ vec2 varTexCoord;
#endif

const vec3 artificialLight = vec3(1.04, 1.04, 1.04);

#ifdef USE_SKINNING
layout (std140) uniform JointMatrices {
	mat4 joints[MAX_JOINTS];
};
#endif

#ifdef ENABLE_DYNAMIC_SHADOWS
uniform vec3 v_LightDirection;
uniform float f_textureresolution;
uniform mat4 m_ShadowViewProj;
uniform float f_shadowfar;
uniform float f_shadow_strength;
uniform float f_timeofday;
uniform vec4 CameraPos;
uniform float xyPerspectiveBias0;
uniform float xyPerspectiveBias1;
uniform float zPerspectiveBias;

VARYING_ float cosLight;
VARYING_ float adj_shadow_strength;
VARYING_ float f_normal_length;
VARYING_ vec3 shadow_position;
VARYING_ float perspective_factor;

vec4 getRelativePosition(in vec4 position)
{
	vec2 l = position.xy - CameraPos.xy;
	vec2 s = l / abs(l);
	s = (1.0 - s * CameraPos.xy);
	l /= s;
	return vec4(l, s);
}

float getPerspectiveFactor(in vec4 relativePosition)
{
	float pDistance = length(relativePosition.xy);
	return pDistance * xyPerspectiveBias0 + xyPerspectiveBias1;
}

vec4 applyPerspectiveDistortion(in vec4 position)
{
	vec4 l = getRelativePosition(position);
	float pFactor = getPerspectiveFactor(l);
	l.xy /= pFactor;
	position.xy = l.xy * l.zw + CameraPos.xy;
	position.z *= zPerspectiveBias;
	return position;
}

#if __VERSION__ >= 130
#define mtsmoothstep smoothstep
#else
float mtsmoothstep(in float edge0, in float edge1, in float x)
{
	float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}
#endif
#endif

void main(void)
{
#ifdef USE_SKINNING
	uvec4 jids = inVertexJointIDs;
	vec4 skinPos = inVertexPosition;
	vec3 skinNormal = inVertexNormal;
	if (inVertexWeights != vec4(0.0)) {
		mat4 mSkin =
				inVertexWeights.x * joints[jids.x] +
				inVertexWeights.y * joints[jids.y] +
				inVertexWeights.z * joints[jids.z] +
				inVertexWeights.w * joints[jids.w];
		skinPos = vec4((mSkin * vec4(inVertexPosition.xyz, 1.0)).xyz, 1.0);
		skinNormal = (mSkin * vec4(inVertexNormal, 0.0)).xyz;
	}
#else
	vec4 skinPos = inVertexPosition;
	vec3 skinNormal = inVertexNormal;
#endif

	gl_Position = mWorldViewProj * skinPos;

	worldPosition = (mWorld * skinPos).xyz;
	vNormal = skinNormal;

	vec4 color = inVertexColor;
	nightRatio = 1.0 - color.a;
	color.rgb = color.rgb * (color.a * dayLight.rgb + nightRatio * artificialLight.rgb) * 2.0;
	color.a = 1.0;
	varColor = clamp(color, 0.0, 1.0);

	#if USE_ARRAY_TEXTURE
	varTexCoord = vec3(inTexCoord0.st, float(inVertexAux));
	#else
	varTexCoord = inTexCoord0.st;
	#endif

#ifdef ENABLE_DYNAMIC_SHADOWS
	if (f_shadow_strength > 0.0) {
		vec3 nNormal;
		f_normal_length = length(vNormal);

		float normalOffsetScale, z_bias;
		float pFactor = getPerspectiveFactor(getRelativePosition(m_ShadowViewProj * mWorld * skinPos));
		if (f_normal_length > 0.0) {
			nNormal = normalize(vNormal);
			cosLight = max(1e-5, dot(nNormal, -v_LightDirection));
			float sinLight = pow(1.0 - pow(cosLight, 2.0), 0.5);
			normalOffsetScale = 2.0 * pFactor * pFactor * sinLight * min(f_shadowfar, 500.0) /
					xyPerspectiveBias1 / f_textureresolution;
			z_bias = 1.0 * sinLight / cosLight;
		} else {
			nNormal = vec3(0.0);
			cosLight = clamp(dot(v_LightDirection, normalize(vec3(v_LightDirection.x, 0.0, v_LightDirection.z))), 1e-2, 1.0);
			float sinLight = pow(1.0 - pow(cosLight, 2.0), 0.5);
			normalOffsetScale = 0.0;
			z_bias = 3.6e3 * sinLight / cosLight;
		}
		z_bias *= pFactor * pFactor / f_textureresolution / f_shadowfar;

		shadow_position = applyPerspectiveDistortion(m_ShadowViewProj * mWorld * (skinPos + vec4(normalOffsetScale * nNormal, 0.0))).xyz;
		shadow_position.z -= z_bias;
		perspective_factor = pFactor;

		if (f_timeofday < 0.2) {
			adj_shadow_strength = f_shadow_strength * 0.5 *
				(1.0 - mtsmoothstep(0.18, 0.2, f_timeofday));
		} else if (f_timeofday >= 0.8) {
			adj_shadow_strength = f_shadow_strength * 0.5 *
				mtsmoothstep(0.8, 0.83, f_timeofday);
		} else {
			adj_shadow_strength = f_shadow_strength *
				mtsmoothstep(0.20, 0.25, f_timeofday) *
				(1.0 - mtsmoothstep(0.7, 0.8, f_timeofday));
		}
	}
#endif
}
