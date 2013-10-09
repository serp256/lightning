// http://www.cocos2d-iphone.org

#ifdef GL_ES
precision mediump float;
#endif

uniform vec3 u_color;
uniform float u_parentAlpha;

void main()
{
	gl_FragColor = (u_color, u_parentAlpha);
}
