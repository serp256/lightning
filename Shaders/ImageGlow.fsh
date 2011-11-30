
#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;
#ifdef GL_ES
uniform mediump float u_pixelSizeX;
uniform mediump float u_pixelSizeY;
#else
uniform float u_pixelSizeX;
uniform float u_pixelSizeY;
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
		float sum = 0.0;

		float k2 = u_glowStrenght;
		 
		//sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 3.0*u_glowSize)).a * u_glowStrenght; 
		//sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 2.0*u_glowSize)).a * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - u_glowSize)).a * k2;
			
		sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + u_glowSize)).a * k2;
		//sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 2.0*u_glowSize)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 3.0*u_glowSize)).a * u_glowStrenght;
			
		//sum += texture2D(u_texture, vec2(v_texCoord.x - 3.0*u_glowSize, v_texCoord.y)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x - 2.0*u_glowSize, v_texCoord.y)).a * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - u_glowSize, v_texCoord.y)).a *k2;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x + u_glowSize, v_texCoord.y)).a * k2;
		//sum += texture2D(u_texture, vec2(v_texCoord.x + 2.0*u_glowSize, v_texCoord.y)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x + 3.0*u_glowSize, v_texCoord.y)).a * u_glowStrenght;
		
		//sum += texture2D(u_texture, vec2(v_texCoord.x - 3.0*u_glowSize, v_texCoord.y - 3.0*u_glowSize)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x - 2.0*u_glowSize, v_texCoord.y- 2.0*u_glowSize)).a * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - u_glowSize, v_texCoord.y- u_glowSize)).a * k2;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x + u_glowSize, v_texCoord.y+ u_glowSize)).a * k2;
		//sum += texture2D(u_texture, vec2(v_texCoord.x + 2.0*u_glowSize, v_texCoord.y+ 2.0*u_glowSize)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x + 3.0*u_glowSize, v_texCoord.y+ 3.0*u_glowSize) ).a * u_glowStrenght;
		
		//sum += texture2D(u_texture, vec2(v_texCoord.x - 3.0*u_glowSize, v_texCoord.y + 3.0*u_glowSize)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x - 2.0*u_glowSize, v_texCoord.y+ 2.0*u_glowSize)).a * u_glowStrenght;
		sum += texture2D(u_texture, vec2(v_texCoord.x - u_glowSize, v_texCoord.y+ u_glowSize)).a * k2;
		
		sum += texture2D(u_texture, vec2(v_texCoord.x + u_glowSize, v_texCoord.y - u_glowSize)).a * k2;
		//sum += texture2D(u_texture, vec2(v_texCoord.x + 2.0*u_glowSize, v_texCoord.y- 2.0*u_glowSize)).a * u_glowStrenght;
		//sum += texture2D(u_texture, vec2(v_texCoord.x + 3.0*u_glowSize, v_texCoord.y- 3.0*u_glowSize)).a  * u_glowStrenght;

		
		clr.r = u_glowColor.r * sum;
		clr.g = u_glowColor.g * sum;
		clr.b = u_glowColor.b * sum;   
		clr.a = sum;
	};

	gl_FragColor = clr;
}

