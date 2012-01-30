
#include "render_stub.h"
#include "math.h"

extern GLuint currentShaderProgram;
extern GLuint boundTextureID;


static int nextPowerOfTwo(int number) {
	int result = 1;
	while (result < number) result *= 2;
	return result;
}


// Shaders

static GLuint compile_shader(GLenum sType, const char* shaderSource) {
	GLuint shader = glCreateShader(sType);
	glShaderSource(shader, 1, &shaderSource, NULL);
	glCompileShader(shader);
	GLint status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
  if(!status)
	{
		GLint logLength = 0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
		char *shaderInfoLog = (char *)malloc(logLength);
		glGetShaderInfoLog(shader, logLength, &logLength, shaderInfoLog);
		printf("shader error: <%s> -> [%s]\n",shaderSource,shaderInfoLog);
		free(shaderInfoLog);
		glDeleteShader(shader);
		return 0;
	};
	return shader;
}

static GLuint simple_vertex_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_VERTEX_SHADER,
			"attribute vec2 a_position; attribute vec2 a_texCoord; varying vec2 v_texCoord; \
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
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision lowp float; \n#endif\n\
				varying vec2 v_texCoord; uniform sampler2D u_texture;\
				void main() {\
					 gl_FragColor = texture2D(u_texture, v_texCoord);\
				}");
	};
	return shader;
}


GLuint create_program(GLuint vShader, GLuint fShader, int cntattribs, char* attribs[]) {
	GLuint program =  glCreateProgram();
	glAttachShader(program, vShader); 
	glAttachShader(program, fShader); 
	int i = 0;
	for (i; i < cntattribs; i++) {
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
    glDetachShader(program,fShader);
    glDeleteProgram(program);
    free(shaderProgramInfoLog);
    return 0;
  }
  return program;
}

GLuint simple_program() {
	static GLuint prg = 0;
	if (prg == 0) {
		printf("create new program\n");
		char *attribs[2] = {"a_position","a_texCoord"};
		prg = create_program(simple_vertex_shader(),simple_fragment_shader(),2,attribs);
		if (prg) {
			glUseProgram(prg);
			glUniform1i(glGetUniformLocation(prg,"u_texture"),0);
			glUseProgram(0);
		}
	};
	return prg;
}

typedef struct {
	GLfloat x;
	GLfloat y;
	GLfloat width;
	GLfloat height;
} clipping;

typedef struct {
  GLuint fbid;
	GLuint tid;
	double width;
	double height;
	clipping clp;
} renderbuffer_t;

// сделать рендер буфер
renderbuffer_t* create_renderbuffer(double width,double height, renderbuffer_t *r) {
	//printf("try create renderbuffer: %f:%f\n",width,height);
  GLuint rtid;
	GLuint iw = ceil(width);
	GLuint ih = ceil(height);
	GLuint legalWidth = nextPowerOfTwo(iw);
	GLuint legalHeight = nextPowerOfTwo(ih);
#ifdef IOS
	if (legalWidth <= 8) {
    if (legalWidth > legalHeight) legalHeight = legalWidth;
    else 
      if (legalHeight > legalWidth * 2) legalWidth = legalHeight/2; 
			if (legalWidth > 16) legalWidth = 16;
	} else {
    if (legalHeight <= 8) legalHeight = 16 < legalWidth ? 16 : legalWidth;
	};
#endif
	// need ios fix here 
  glGenTextures(1, &rtid);
  glBindTexture(GL_TEXTURE_2D, rtid);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, legalWidth, legalHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	checkGLErrors("create renderbuffer texture");
  glBindTexture(GL_TEXTURE_2D,0);
  GLuint fbid;
  glGenFramebuffers(1, &fbid);
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rtid,0);
	checkGLErrors("bind framebuffer with texture");
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    printf("framebuffer %d status: %d\n",fbid,glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return NULL;
  };
  glBindFramebuffer(GL_FRAMEBUFFER,0);
  r->fbid = fbid;
  r->tid = rtid;
	r->clp = (clipping){0.,0.,(width / legalWidth),(height / legalHeight)};
  r->width = width;
  r->height = height;
//	printf("framebuffer %d with texture %d of size %d:%d for %f:%f created\n",fbid,rtid,legalWidth,legalHeight,width,height);
	//r->realWidth = realWidth;
	//r->realHeight = realHeight;
	//printf("created new fb: %d with %d\n",fbid,rtid);
  return r;
}

void delete_renderbuffer(renderbuffer_t *rb) {
	//printf("delete rb: %d - %d\n",rb->fbid,rb->tid);
	glDeleteTextures(1,&rb->tid);
	glDeleteFramebuffers(1,&rb->fbid);
	//printf("delete successfully\n");
}

static GLfloat quads[4][2];
static GLfloat texCoords[4][2] = {{0.,0.},{1.,0.},{0.,1.},{1.,1.}};

void drawTexture(renderbuffer_t *rb,GLuint textureID, double w, double h, clipping *clp) {

	glBindFramebuffer(GL_FRAMEBUFFER,rb->fbid);
	GLsizei bw = ceil(rb->width);
	GLsizei bh = ceil(rb->height);


  glViewport(0, 0,bw,bh);
	glClear(GL_COLOR_BUFFER_BIT);
	glBindTexture(GL_TEXTURE_2D,textureID);

	double dx = ((double)bw - w) / bw;
	double dy = ((double)bh - h) / bh;
	double x = w / bw;
	double y = h / bh;

	//printf("draw texture %d [%f:%f] to rb %d [%f:%f] -> viewport [%d:%d]\n",textureID,w,h,rb->fbid,rb->width,rb->height, bw, bh);

	//  надо в левый сука угол сместить каким-то хуем блядь нахуй
	quads[0][0] = -x - dx;
	quads[0][1] = y - dy;
	quads[1][0] = x - dx;
	quads[1][1] = quads[0][1];
	quads[2][0] = quads[0][0];
	quads[2][1] = -y - dy;
	quads[3][0] = quads[1][0];
	quads[3][1] = quads[2][1];

	//printf("quads: [%f:%f] [%f:%f] [%f:%f] [%f:%f]\n", quads[0][0], quads[0][1], quads[1][0], quads[1][1], quads[2][0], quads[2][1], quads[3][0], quads[3][1]);

	//printf("clp: %f:%f:%f:%f\n",clp->x,clp->y,clp->width,clp->height);
	texCoords[0][0] = clp->x;
	texCoords[0][1] = clp->y;
	texCoords[1][0] = clp->x + clp->width;
	texCoords[1][1] = clp->y;
	texCoords[2][0] = clp->x;
	texCoords[2][1] = clp->y + clp->height;
	texCoords[3][0] = texCoords[1][0];
	texCoords[3][1] = texCoords[2][1];

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);
	glVertexAttribPointer(lgVertexAttrib_Position,2,GL_FLOAT,GL_FALSE,0,quads);
	glVertexAttribPointer(lgVertexAttrib_TexCoords,2,GL_FLOAT,GL_FALSE,0,texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// можно нахуй скипнуть это дело 
	glBindTexture(GL_TEXTURE_2D,0);
	glBindFramebuffer(GL_FRAMEBUFFER,0); 

}

///////////
/// Filter common 
//////

static void filter_finalize(value fltr) {
	filter *f = FILTER(fltr);
	if (f->finalize != NULL) f->finalize(f->data);
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


value make_filter(filterRender render,filterFinalize finalize, void *data) {
	filter *f = (filter *)caml_stat_alloc(sizeof(filter));
	f->render = render;
	f->finalize = finalize;
	f->data = data;
	value res = caml_alloc_custom(&filter_ops,sizeof(filter*),1,0);
	FILTER(res) = f;
	return res;
}

///////////////
//// GLOW
//////////////


/*
static GLuint glow_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"varying  vec2 v_texCoord;uniform  vec3 u_color; uniform sampler2D u_texture;\
				void main() {\
					float alpha = texture2D(u_texture, v_texCoord).a; \
					gl_FragColor = vec4(u_color,alpha);\
				}");
	};
	return shader;
};
*/

struct glowData 
{
	color3F color;
	GLfloat strength;
};

static void glowFilter(sprogram *sp,void *data) {
	struct glowData *d = (struct glowData*)data;
	glUniform3f(sp->uniforms[1],d->color.r,d->color.g,d->color.b);
	glUniform1f(sp->uniforms[2],d->strength);
	/*glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D,d->textureID);
	glActiveTexture(GL_TEXTURE0); // надо бы вернуть, а как после рендеринга еще вернуть? или хуй с ней ?
	glUniform1f(sp->uniforms[2],d->strenght);*/
	// здесь бы все отрендерить нахуй
}

static void glowFilterFinalize(void *data) {
	struct glowData *d = (struct glowData*)data;
	caml_stat_free(d);
}

value ml_filter_glow(value color, value strength) {
	struct glowData *gd = (struct glowData*)caml_stat_alloc(sizeof(struct glowData));
	gd->color = COLOR3F_FROM_INT(Long_val(color));
	gd->strength = (GLfloat)Long_val(strength);
	return make_filter(&glowFilter,&glowFilterFinalize,gd);
}

void ml_glow_resize(value framebufferID,value textureID, value width, value height, value clip, value count) {
	/* не понятно как тут разрулица надо */ 
	renderbuffer_t rb;
	rb.fbid = Long_val(framebufferID);
	rb.tid = Long_val(textureID);
	rb.width = Double_val(width);
	rb.height = Double_val(height);
	if (clip != 1) {
		value c = Field(clip,0);
		rb.clp.x = Double_field(c,0);
		rb.clp.y = Double_field(c,1);
		rb.clp.width = Double_field(c,2);
		rb.clp.height = Double_field(c,3);
	} else { 
		rb.clp.x = 0;
		rb.clp.y = 0;
		rb.clp.width = 1.;
		rb.clp.height = 1.;
	};
	glDisable(GL_BLEND);
	int gsize = Int_val(count);
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	glClearColor(0.,0.,0.,0.);
	GLuint simplePrg = simple_program();
	glUseProgram(simplePrg);
	renderbuffer_t *crb = &rb;
	renderbuffer_t *rbfs = caml_stat_alloc((gsize-1)*sizeof(renderbuffer_t));
	int i;
	double w = rb.width, h = rb.height;
	renderbuffer_t *rbfp = rbfs;
	for (i = 1; i < gsize; i++) {
		w /= 2;
		h /= 2;
		create_renderbuffer(w,h,rbfp);
		checkGLErrors("create renderbuffer");
		drawTexture(rbfp,crb->tid,w,h,&crb->clp);
		checkGLErrors("draw forward");
		crb = rbfp;
		rbfp += 1;
	};
	rbfp = rbfs + (gsize - 2);
	renderbuffer_t *prbfp;
	for (i = 2; i < gsize ; i++) {
		prbfp = rbfp - 1;
		drawTexture(prbfp,rbfp->tid,prbfp->width,prbfp->height,&rbfp->clp);
		checkGLErrors("draw back");
		delete_renderbuffer(rbfp);
		rbfp = prbfp;
	};
	checkGLErrors("before last draw");
	drawTexture(&rb,rbfs->tid,rb.width,rb.height,&rbfs->clp);
	delete_renderbuffer(rbfs);
	caml_stat_free(rbfs);
	glUseProgram(0);
	boundTextureID = 0;
	currentShaderProgram = 0;
	set_framebuffer_state(&fstate);
	glEnable(GL_BLEND);
}


void ml_glow_resize_byte(value * argv, int n) {
	ml_glow_resize(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5]);
}


/*
// не знаешь как сделать, сделай хоть какнить
value ml_filter_glow(value textureID, value ow, value oh, value clipping, value glow) {
	checkGLErrors("create glow filter");
	double width = Double_val(ow); 
	double height = Double_val(oh);
	int gsize = Long_val(Field(glow,0));
	color3F gcolor = COLOR3F_FROM_INT(Long_val(Field(glow,1)));
	printf("glow: w=%f,h=%f,gsize=%d,color:[%f:%f:%f]\n",width,height,gsize,gcolor.r,gcolor.g,gcolor.b);
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	glClearColor(0.,0.,0.,0.);
	char *attribs[2] = {"a_position","a_texCoord"};
	GLuint glowPrg = create_program(simple_vertex_shader(),glow_fragment_shader(),2,attribs); // FIXME: cache it
	checkGLErrors("created glowPrg");
	glUseProgram(glowPrg);
	glUniform3f(glGetUniformLocation(glowPrg,"u_color"),gcolor.r,gcolor.g,gcolor.b); // FIXME: getLoc
	checkGLErrors("glowPrg uniforms u_color");
	glUniform1i(glGetUniformLocation(glowPrg,"u_texture"),0);
	checkGLErrors("bind uniform u_texture");

	renderbuffer_t rb;
	GLuint wdth = nextPowerOfTwo((GLuint)width) >> 1;
	GLuint hght = nextPowerOfTwo((GLuint)height) >> 1;
	create_renderbuffer(w,h,&rb);
	drawTexture(&rb,Long_val(textureID),(GLuint)width,(GLuint)height,clipping,0.5,-0.5); // рисуем в 2 раза меньше
	checkGLErrors("after draw texture with glow program");

	if (gsize > 1) {
		GLuint simplePrg = simple_program();
		glUseProgram(simplePrg);
		renderbuffer_t *crb = &rb;
		renderbuffer_t **rbfs = caml_stat_alloc((gsize-1)*sizeof(renderbuffer_t));
		int i;
		for (i = 1; i < gsize; i++) {
			w >>= 1;
			h >>= 1;
			create_renderbuffer(w,h,rbfs[i-1]);
			drawTexture(rbfs[i-1],crb->tid,crb->width,crb->height,1,0.5,0.5);
		};
		for (i = gsize - 1; i > 0; i--) {
			drawTexture(rbfs[i-1],rbfs[i]->tid,rbfs[i]->width,rbfs[i]->height,1,2,2);
			delete_renderbuffer(rbfs[i]);
		};
		drawTexture(&rb,rbfs[0]->tid,rbfs[0]->width,rbfs[0]->height,1,2,2);
		delete_renderbuffer(rbfs[0]);
		caml_stat_free(rbfs);
		glUseProgram(simplePrg);
	};
	// вроде бы все отрендерили 
	glDeleteFramebuffers(1,&rb.fbid);
	set_framebuffer_state(&fstate);

	struct glowData *gd = (struct glowData*)caml_stat_alloc(sizeof(struct glowData));
	gd->textureID = rb.tid;
	gd->texQuad.bl.v = (vertex2F){0,0};
	qd->texQuad.bl.tex = (tex2F){0,0};
	gd->texQuad.br.v = (vertex2F){wdth,0};
	qd->texQuad.br.tex = (tex2F){1,0};
	gd->texQuad.tl.v = (vertex2F){0,hgth};
	gd->texQuad.tl.tex = (tex2F){0,1};
	gd->texQuad.tr.v = (vertex2F){wdth,hgth};
	gd->texQuad.tr.tex = (tex2F){1,1};
	gd->strenght = Long_val(Field(glow,2));
	set_framebuffer_state(&fstate);
	return make_filter(&glowFilter,&glowFilterFinalize,gd);
}
*/


///////////////////
//// COLOR MATRIX
/////////////////////

static void colorMatrixFilter(sprogram *sp,void *data) {
	glUniform1fv(sp->uniforms[1],20,(GLfloat*)data);
}

value ml_filter_cmatrix(value matrix) {
	return make_filter(&colorMatrixFilter,NULL,Caml_ba_data_val(matrix));
}
