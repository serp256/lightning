#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D u_pallete;
uniform float u_parentAlpha;

void main()
{
	vec4 idx = texture2D(u_texture,v_texCoord);
	// вычислить сцука индекc нахуй
	vec4 color = v_fragmentColor * texture2D(u_pallete, vec2(idx.r,idx.a));
	gl_FragColor = color * u_parentAlpha; 
}
