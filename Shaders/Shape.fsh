// http://www.cocos2d-iphone.org

#ifdef GL_ES
precision mediump float;
#endif

uniform float u_parentAlpha;
uniform vec3 u_color;
uniform float u_alpha;

void main()
{
	gl_FragColor = vec4(u_color, u_parentAlpha * u_alpha);
}
