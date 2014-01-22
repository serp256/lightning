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
uniform sampler2D u_alpha;
uniform float u_parentAlpha;

void main()
{
	vec4 color = texture2D(u_texture, v_texCoord);
	color.a = texture2D(u_alpha, v_texCoord).r;
	gl_FragColor = v_fragmentColor * color * u_parentAlpha;
}
