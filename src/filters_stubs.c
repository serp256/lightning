
#include "render_stub.h"

int nextPowerOfTwo(int number) {
	int result = 1;
	while (result < number) result *= 2;
	return result;
}

static void filter_finalize(value fltr) {
	filter *f = FILTER(fltr);
	caml_stat_free(f->f_data);
	caml_stat_free(f);
}

struct custom_operations filter_ops = {
  "pointer to a filter",
  filter_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


value make_filter(filterFun fun,void *data) {
	filter *f = (filter *)caml_stat_alloc(sizeof(filter));
	f->f_fun = fun;
	f->f_data = data;
	value res = caml_alloc_custom(&filter_ops,sizeof(filter*),1,0);
	FILTER(res) = f;
	return res;
}


// Shaders

static GLuint compilehader(GLenum sType, GLint const char* chaderSource) {
	GLuint result = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(result, 1, shaderSource, NULL);
	GLint status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
  if(status == 0)
	{
		GLint logLength = 0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
		char *shaderInfoLog = (char *)malloc(logLength);
		glGetShaderInfoLog(vertexshader, logLength, &logLength, shaderInfoLog);
		printf("shader error: %s\n",shaderInfoLog);
		free(shaderInfoLog);
		glDeleteShader(result);
		return 0;
	};
	return result;
}

static GLuint simpleVertexShader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compileShader(GL_VERTEX_SHADER,
			"attribute  vec2 a_position; attribute  vec2 a_texCoord; varying vec2 v_texCoord; \
			void main(void) { \
			gl_Position = vec4(a_position, 0.0, 1.0); \
			v_texCoord = a_texCoord; \
			}");
	};
	return shader;
}

static GLuint simpleFragmentShader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shder = compileShader(GL_FRAGMENT_SHADER,
				"varying vec2 v_texCoord; uniform sampler2D u_texture;\
				void main() {\
					 gl_FragColor = texture2D(u_texture, v_texCoord);\
				}");
	};
	return shader;
}


GLuint createProgram(GLuint vShader, GLuint fShader, int cntattribs, char* attribs) {
	GLuint program =  glCreateProgram();
	glAttachShader(program, vShader); 
	glAttachShader(program, fShader); 
	for (i = 0; i < cntattribs; i++) {
    glBindAttribLocation(program,i,attribs[i]);
  };
  glLinkProgram(program);
	int IsLinked;
  glGetProgramiv(program, GL_LINK_STATUS, (int *)&IsLinked);
  if(IsLinked == 0)
  {
		int maxLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &maxLength);
    char *shaderProgramInfoLog = (char *)malloc(maxLength);
    glGetProgramInfoLog(program, maxLength, &maxLength, shaderProgramInfoLog);
    printf("program error: %s\n",shaderProgramInfoLog);
    glDetachShader(program,vShader);
    glDetachShader(progarm,fShader);
    glDeleteProgram(program);
    free(shaderProgramInfoLog);
    return 0;
  }
  return program;
}

typedef struct {
  GLuint fbid;
	GLuint tid;
	int width;
	int height;
} renderbuffer_t;

// сделать рендер буфер
renderbuffer_t* create_renderbuffer(int width,int height, renderbuffer_t *r) {
  GLuint rtid;
  glGenTextures(1, &rtid);
  glBindTexture(GL_TEXTURE_2D, rtid);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glBindTexture(GL_TEXTURE_2D,0);
  GLuint fbid;
  glGenFramebuffers(1, &fbid);
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rtid,0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    printf("framebuffer status: %d\n",glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return NULL;
  };
  glBindFramebuffer(GL_FRAMEBUFFER,0);
  r->fbid = fbid;
  r->tid = rtid;
  r->width = width;
  r->height = height;
  return r;
}

///////////////
//// GLOW
//////////////


static GLuint glowFragmentShader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shder = compileShader(GL_FRAGMENT_SHADER,
				"varying  vec2 v_texCoord;uniform  vec3 u_color;uniform sampler2D u_texture;\
				void main() {\
					gl_FragColor = texture2D(u_texture, v_texCoord);
				}");
	};
	return shader;
};

struct glowData 
{
	GLUint blurTextureID:
	GLfloat glowStrenght;
};

static void glowFilter(sprogram *sp,void *data) {
	struct glowData *d = (struct glowData*)data;
	glUniform1f(sp->other_uniforms[0],d->glowSize);
	glUniform1f(sp->other_uniforms[1],d->glowStrenght);
	glUniform3fv(sp->other_uniforms[2],1,(GLfloat*)&(d->glowColor));
}

value ml_filter_glow(value w, value h, value textureID, value clipping, value glow) {
	double width = Double_val(w); 
	double height = Double_val(h);
	double glowSize = Double_val(Field(glow,0));
	glClearColor(0.,0.,0.,0.);
	// самый гемор сделать ебанный отступ сдеся 

	renderbuffer_t rb1;
	create_renderbuffer((GLuint)w >> 1, (GLuint)h >> 1, &rb1);
	// нужно как-то отрендерить!!!!  как? 
	// просто текстуру? или как?
	// раздвигать сцука сложно нахуй

	/*
	struct glowData *gd = (struct glowData*)caml_stat_alloc(sizeof(struct glowData));
	gd->glowStrenght = Double_val(Field(glow,1));
	gd->glowColor = COLOR3F_FROM_INT(Field(glow,2));
	*/

	return make_filter(&glowFilter,gd);
}


///////////////////
//// COLOR MATRIX
/////////////////////

static void colorMatrixFilter(sprogram *sp,void *data) {
	glUniform1fv(sp->other_uniforms[0],20,(GLfloat*)data);
}

value ml_filter_cmatrix(value matrix) {
	return make_filter(&colorMatrixFilter,Caml_ba_data_val(matrix));
}



/////////////////////////
///// COLOR MATRIX GLOW
////////////////////

struct cMatrixGlow {
	GLfloat *cmatrix;
	struct glowData glow;
};

void cMatrixGlowFilter(sprogram *sp,void *data) {
	struct cMatrixGlow *gd = (struct cMatrixGlow*)data;
	glUniform1fv(sp->other_uniforms[0],20,(GLfloat*)gd->cmatrix);
	glUniform1f(sp->other_uniforms[1],gd->glow.glowSize);
	glUniform1f(sp->other_uniforms[2],gd->glow.glowStrenght);
	glUniform3fv(sp->other_uniforms[3],1,(GLfloat*)&(gd->glow.glowColor));
}

value ml_filter_cmatrix_glow(value matrix,value glow) {
	struct cMatrixGlow *gd = (struct cMatrixGlow*)caml_stat_alloc(sizeof(struct cMatrixGlow));
	gd->cmatrix = Caml_ba_data_val(matrix);
	gd->glow.glowSize = Double_val(Field(glow,0)) / 1000.;
	gd->glow.glowStrenght = Double_val(Field(glow,1));
	gd->glow.glowColor = COLOR3F_FROM_INT(Field(glow,2));
	return make_filter(&cMatrixGlowFilter,gd);
}
