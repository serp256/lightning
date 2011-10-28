// http://www.cocos2d-iphone.org

#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform float u_parentAlpha;

void main()
{
	gl_FragColor = v_fragmentColor * texture2D(u_texture, v_texCoord);
	gl_FragColor.a *= u_parentAlpha;
}
