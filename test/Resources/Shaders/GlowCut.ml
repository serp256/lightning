

#ifdef GL_ES
precision lowp float;
#endif

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform float u_parentAlpha; // this is uniform not used here

void main(void)
{
  float alpha = texture2D(u_texture,v_texCoord).a;
  if (alpha == 1.0)
    gl_FragColor = vec4(0.,0.,0.,0.);
  else glFragColor 
}
