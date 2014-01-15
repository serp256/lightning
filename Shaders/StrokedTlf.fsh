#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
#ifdef GL_ES
varying highp vec2 v_texCoord;
#else
varying vec2 v_texCoord;
#endif
uniform sampler2D u_texture;
uniform float u_parentAlpha;
uniform vec4 u_strokeColor;

void main()
{
	vec4 lumal = texture2D(u_texture, v_texCoord);
	vec4 glyphColor = v_fragmentColor * lumal.a;

	if (u_strokeColor.a == 0.) {
		gl_FragColor = glyphColor * u_parentAlpha;	
	} else {
		vec4 u_strokeColor = u_strokeColor * lumal.r;
		gl_FragColor = vec4((1. - glyphColor.a) * u_strokeColor.rgb + glyphColor.rgb, u_strokeColor.a + glyphColor.a) * u_parentAlpha;
	}
}
