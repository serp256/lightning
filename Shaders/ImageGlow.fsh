
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform sampler2D u_btexture;
uniform float u_strength;
uniform float u_parentAlpha;

void main(void)
{
	gl_FragColor = texture2D(u_btexture,v_texCoord);
/*
    vec4 orig = texture2D(u_texture, v_texCoord);
		if (orig.a < 1.) {
			vec4 c = texture2D(u_btexture, v_texCoord);
			c.a *= u_strength;
			vec4 r = mix(orig,c,1. - orig.a);
			gl_FragColor = r;
		} else gl_FragColor = orig * v_fragmentColor;
		gl_FragColor.a *= u_parentAlpha;
*/
}
