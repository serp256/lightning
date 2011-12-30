
#ifdef GL_ES
precision lowp float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform float u_strength;
uniform vec3 u_color;
uniform float u_parentAlpha; 

void main(void)
{
	gl_FragColor = vec4(u_color,texture2D(u_texture,v_texCoord).a * u_strength * u_parentAlpha);
}
