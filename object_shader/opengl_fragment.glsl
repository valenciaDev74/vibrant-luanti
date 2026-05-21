VARYING_ vec4 varColor;

#if USE_ARRAY_TEXTURE
uniform sampler2DArray baseTexture;
VARYING_ vec3 varTexCoord;
#else
uniform sampler2D baseTexture;
VARYING_ vec2 varTexCoord;
#endif

void main(void)
{
	vec4 texColor = texture(baseTexture, varTexCoord);

	if (texColor.a < 0.1) {
		discard;
	}

	vec4 finalColor = texColor * varColor;
	gl_FragData[0] = finalColor;
}
