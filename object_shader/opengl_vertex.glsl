uniform vec3 dayLight;

VARYING_ vec4 varColor;

#if USE_ARRAY_TEXTURE
VARYING_ vec3 varTexCoord;
#else
VARYING_ vec2 varTexCoord;
#endif

const vec3 artificialLight = vec3(1.04, 1.04, 1.04);

void main(void)
{
	gl_Position = mWorldViewProj * inVertexPosition;

	vec4 color = inVertexColor;
	float nightRatio = 1.0 - color.a;
	color.rgb = color.rgb * (color.a * dayLight.rgb + nightRatio * artificialLight.rgb) * 2.0;
	color.a = 1.0;
	varColor = clamp(color, 0.0, 1.0);

	#if USE_ARRAY_TEXTURE
	varTexCoord = vec3(inTexCoord0.st, float(inVertexAux));
	#else
	varTexCoord = inTexCoord0.st;
	#endif
}
