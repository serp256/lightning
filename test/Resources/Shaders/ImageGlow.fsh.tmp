
#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;
#ifdef GL_ES
uniform highp float u_glowSize;
#else
uniform float u_glowSize;
#endif
uniform float u_parentAlpha;
uniform float u_glowStrenght;
uniform vec3 u_glowColor;

void main()
{
	
	vec4 clr = v_fragmentColor * texture2D(u_texture, v_texCoord);
	clr.a *= u_parentAlpha;

	if (clr.a < 0.8)
	{
		vec4 sum = vec4(0.0,0.0,0.0,0.0); 

		float k2 = u_glowStrenght;
		 
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 3.0*u_glowSize)) * u_glowStrenght; 
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 2.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - u_glowSize)) * k2;
			
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + u_glowSize)) * k2;
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 2.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 3.0*u_glowSize)) * u_glowStrenght;
			
		sum += texture2D(u_texture, vec2(v_texCoord.x - 3.0*u_glowSize, v_texCoord.y)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - 2.0*u_glowSize, v_texCoord.y)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - u_glowSize, v_texCoord.y)) *k2;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x + u_glowSize, v_texCoord.y)) * k2;
		sum += texture2D(u_texture, vec2(v_texCoord.x + 2.0*u_glowSize, v_texCoord.y)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x + 3.0*u_glowSize, v_texCoord.y)) * u_glowStrenght;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x - 3.0*u_glowSize, v_texCoord.y - 3.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - 2.0*u_glowSize, v_texCoord.y- 2.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - u_glowSize, v_texCoord.y- u_glowSize)) * k2;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x + u_glowSize, v_texCoord.y+ u_glowSize)) * k2;
		sum += texture2D(u_texture, vec2(v_texCoord.x + 2.0*u_glowSize, v_texCoord.y+ 2.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x + 3.0*u_glowSize, v_texCoord.y+ 3.0*u_glowSize) ) * u_glowStrenght;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x - 3.0*u_glowSize, v_texCoord.y + 3.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - 2.0*u_glowSize, v_texCoord.y+ 2.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - u_glowSize, v_texCoord.y+ u_glowSize)) * k2;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x + u_glowSize, v_texCoord.y- u_glowSize)) * k2;
		sum += texture2D(u_texture, vec2(v_texCoord.x + 2.0*u_glowSize, v_texCoord.y- 2.0*u_glowSize)) * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x + 3.0*u_glowSize, v_texCoord.y- 3.0*u_glowSize))  * u_glowStrenght;

		
		sum.r = u_glowColor.r * sum.a;
		sum.g = u_glowColor.g * sum.a;
		sum.b = u_glowColor.b * sum.a;   
		clr = sum;
	};

	gl_FragColor = clr;
}

