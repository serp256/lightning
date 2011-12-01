
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

static GLuint compile_shader(GLenum sType, GLint const char* chaderSource) {
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

static GLuint simple_vertex_shader() {
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

static GLuint simple_fragment_shader() {
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


GLuint create_program(GLuint vShader, GLuint fShader, int cntattribs, char* attribs) {
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


static GLuint glow_fragment_shader() {
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

static GLfloat quads[4][2];
static GLfloat texCoords[4][2];

void drawTexture(renderbuffer_t *rb,GLuint textureID, GLuint w,GLuint h,float sx,float sy) {

	glBindFramebuffer(GL_FRAMEBUFFER,rb->fbid);
  glViewport(0, 0,rb->width, rb->height);
	glBindTexture(textureID);

	// пропорции относительно центра 
	double x = ((double)w / rb->width) * sx;
	double y = ((double)h / rb->height) * sy;
	double fdx = ((double)dx / rb->width);
	double fdy = ((double)dy / rb->height);
	quads[0][0] = -x + fdx;
	quads[0][1] = y + fdy;
	quads[1][0] = x + fdx;
	quads[1][1] = y + fdy;
	quads[2][0] = -x + fdx;
	quads[2][1] = -y + fdy;
	quads[3][0] = x + fdx;
	quads[3][1] = -y + fdy;

	if (clipping != 1) {
		value c = Field(clipping,0);
		double x = Double_field(c,0);
		double y = Double_field(c,1);
		double width = Double_field(c,2);
		double height = Double_field(c,3);
		texCoods[0][0] = x;
		texCoords[0][1] = y;
		texCoords[1][0] = x + width;
		texCoords[1][1] = y;
		texCoords[2][0] = x;
		texCoords[2][1] = y + height;
		texCoords[3][0] = x + width;
		texCoords[3][1] = y + height;
	} else {
		texCoods[0][0] = 0;
		texCoords[0][1] = 0;
		texCoords[1][0] = 1;
		texCoords[1][1] = 0;
		texCoords[2][0] = 0;
		texCoords[2][1] = 1;
		texCoords[3][0] = 1;
		texCoords[3][1] = 1;
	};

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);
	glVertexAttribPointer(lgVertexAttrib_Position,2,GL_FLOAT,GL_FALSE,0,quads);
	glVertexAttribPointer(lgVertexAttrib_TexCoords,2,GL_FLOAT,GL_FALSE,0,texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// можно нахуй скипнуть это дело 
	glBindTexture(0);
	glBindFramebuffer(0); // а надо бы сцука стары забиндить нахуй, и старый viewPort

}

value ml_filter_glow(value textureID, value w, value h, value clipping, value glow) {
	double width = Double_val(w); 
	double height = Double_val(h);
	double glowSize = Long_val(Field(glow,0));
	glClearColor(0.,0.,0.,0.);
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	// не знаешь как сделать, сделай хоть какнить
	GLuint simple_vshader = simple_vertex_shader();
	char *attribs[2] = {"a_position","a_texCoord"};
	GLuint glowPrg = create_program(simple_vshader,glow_fragment_shader(),2,attribs);
	glUseProgram(glowPrg);
	glUniform1i(glGetUniformLocation(glowPrg,"u_texture"),0);

	renderbuffer_t rb1;
	GLuint w = ((GLuint)width) >> 1;
	GLuint h = ((GLuint)height) >> 1;
	create_renderbuffer(w,h,&rb1);
	drawTexture(&rb1,textureID,(GLuint)width,(GLuint)height,clipping,0.5,0.5); // нарисует по центру красным

	// и хорошо бы ее в текстуре закэшировать нахуй как-то вдруг надо будет для сцука этойже текстуры въебать
	// а можно и здесь этот кэш организовать, ладно хуй с ним потом видно будет
	if (glowSize > 1) {
		GLuint simplePrg = create_program(simple_vshader,simple_fragment_shader(),2,attribs);
		renderbuffer_t *crb = rb1;
		renderbuffer_t *rbfs[glowSize - 1];
		for (int i = 1; i < glowSize; i++) {
			w >>= 1;
			h >>= 1;
			renderbuffer_t rb;
			create_renderbuffer(w,h,&rb);
			drawTexture(&rb,crb->tid,crb->width,crb->height,0.5,0.5);
		};
	}
	
	/*
	struct glowData *gd = (struct glowData*)caml_stat_alloc(sizeof(struct glowData));
	gd->glowStrenght = Double_val(Field(glow,1));
	gd->glowColor = COLOR3F_FROM_INT(Field(glow,2));
	*/

	set_framebuffer_state(&fstate);
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
