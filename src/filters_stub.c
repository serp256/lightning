
#include "texture_common.h"
#include "render_stub.h"
#include <caml/callback.h>
#include "math.h"

extern GLuint currentShaderProgram;

typedef struct {
	GLuint prg;
	GLint uniforms[4];
} prg_t;

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
		fprintf(stderr,"shader error: <%s> -> [%s]\n",shaderSource,shaderInfoLog);
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
			"attribute vec4 a_position; attribute vec2 a_texCoord; varying vec2 v_texCoord; \
			void main(void) { \
			gl_Position = a_position; \
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
	int i;
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
    fprintf(stderr,"program error: %s\n",shaderProgramInfoLog);
    glDetachShader(program,vShader);
    glDetachShader(program,fShader);
    glDeleteProgram(program);
    free(shaderProgramInfoLog);
    return 0;
  }
  return program;
}

static prg_t* simple_program() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		PRINT_DEBUG("create new program\n");
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),simple_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
		}
	} else glUseProgram(prg.prg);
	return &prg;
}

value create_ml_texture(renderbuffer_t *rb) {
	CAMLparam0();
	CAMLlocal5(mlTextureID,width,height,clip,res);
	static value *mlf = NULL;
	if (mlf == NULL) mlf = (value*)caml_named_value("create_ml_texture");
	if (!IS_CLIPPING(rb->clp)) {
		clip = caml_alloc_tuple(1);
		Store_field(clip,0,caml_alloc(4 * Double_wosize,Double_array_tag));
		Store_double_field(Field(clip,0),0,rb->clp.x);
		Store_double_field(Field(clip,0),1,rb->clp.y);
		Store_double_field(Field(clip,0),2,rb->clp.width);
		Store_double_field(Field(clip,0),3,rb->clp.height);
	} else clip = Val_unit;
	//clip = Val_unit;
	fprintf(stderr,"alloc new c texture: %d\n",rb->tid);
	mlTextureID = alloc_texture_id(rb->tid,rb->width * rb->height * 4);
	//fprintf(stderr,"allocated new mlTextureID: %ld\n",mlTextureID);
	//width = caml_copy_double((double)nextPowerOfTwo(ceil(rb->width)));
	width = caml_copy_double(rb->width);
	//height = caml_copy_double((double)nextPowerOfTwo(ceil(rb->height)));
	height = caml_copy_double(rb->height);
	value params[4];
	params[0] = mlTextureID;
	params[1] = width;
	params[2] = height; 
	params[3] = clip;
	res = caml_callbackN(*mlf,4,params);
	CAMLreturn(res);
}

static GLfloat quads[4][2] = {{-1.,-1.},{1.,-1.},{-1.,1.},{1.,1.}};
static GLfloat texCoords[4][2] = {{0.,0.},{1.,0.},{0.,1.},{1.,1.}};

static inline double min(double f1,double f2) {
	return f1 < f2 ? f1 : f2;
}


static void drawRenderbuffer(renderbuffer_t *drb,renderbuffer_t *srb,int clear) {
	fprintf(stderr,"drawRenderbuffer %d to %d\n",srb->fbid,drb->fbid);
	glBindFramebuffer(GL_FRAMEBUFFER,drb->fbid);
  glViewport(drb->vp.x, drb->vp.y,drb->vp.w,drb->vp.h);
	if (clear) glClear(GL_COLOR_BUFFER_BIT);
	glBindTexture(GL_TEXTURE_2D,srb->tid);
	clipping *clp = &srb->clp;
	texCoords[0][0] = clp->x;
	texCoords[0][1] = clp->y;
	texCoords[1][0] = clp->x + clp->width;
	texCoords[1][1] = clp->y;
	texCoords[2][0] = clp->x;
	texCoords[2][1] = clp->y + clp->height;
	texCoords[3][0] = texCoords[1][0];
	texCoords[3][1] = texCoords[2][1];
	glVertexAttribPointer(lgVertexAttrib_Position,2,GL_FLOAT,GL_FALSE,0,quads);
	glVertexAttribPointer(lgVertexAttrib_TexCoords,2,GL_FLOAT,GL_FALSE,0,texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

/*
void drawTexture(renderbuffer_t *rb,GLuint textureID, double w, double h, clipping *clp,int clear) {

	glBindFramebuffer(GL_FRAMEBUFFER,rb->fbid);


	double x = min(w / rb->vp.w,1.);
	double y = min(h / rb->vp.h,1.); 

	PRINT_DEBUG("draw texture %d [%f:%f] to rb [%d=%d] [%f:%f] -> viewport [%d:%d:%d:%d], quads: [%f,%f]\n",textureID,w,h,rb->fbid,rb->tid,rb->width,rb->height, rb->vp.x, rb->vp.y, rb->vp.w, rb->vp.h,  x, y);

  glViewport(rb->vp.x, rb->vp.y,rb->vp.w,rb->vp.h);
	if (clear) glClear(GL_COLOR_BUFFER_BIT);
	glBindTexture(GL_TEXTURE_2D,textureID);

	quads[0][0] = -x;
	quads[0][1] = -y;
	quads[1][0] = x;
	quads[1][1] = -y;
	quads[2][0] = -x; 
	quads[2][1] = y;
	quads[3][0] = x;
	quads[3][1] = y;

	PRINT_DEBUG("quads: [%f:%f],[%f:%f],[%f:%f],[%f:%f]",quads[0][0],quads[0][1],quads[1][0],quads[1][1],quads[2][0],quads[2][1],quads[3][0],quads[3][1]);
	

	texCoords[0][0] = clp->x;
	texCoords[0][1] = clp->y;
	texCoords[1][0] = clp->x + clp->width;
	texCoords[1][1] = clp->y;
	texCoords[2][0] = clp->x;
	texCoords[2][1] = clp->y + clp->height;
	texCoords[3][0] = texCoords[1][0];
	texCoords[3][1] = texCoords[2][1];

	checkGLErrors("before draw texture");

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);
	glVertexAttribPointer(lgVertexAttrib_Position,2,GL_FLOAT,GL_FALSE,0,quads);
	glVertexAttribPointer(lgVertexAttrib_TexCoords,2,GL_FLOAT,GL_FALSE,0,texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	checkGLErrors("after draw texture");
	// можно нахуй скипнуть это дело 
	//glBindTexture(GL_TEXTURE_2D,0);
	//glBindFramebuffer(GL_FRAMEBUFFER,0); 
}
*/

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
static GLuint final_glow_vertex_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_VERTEX_SHADER,
			"attribute vec2 a_position; attribute vec2 a_texCoord; attribute vec2 a_texCoordOrig; varying vec2 v_texCoord; varying vec2 v_texCoordOrig;\
			void main(void) { \
			gl_Position = vec4(a_position, 0.0, 1.0); \
			v_texCoord = a_texCoord; \
			v_texCoordOrig = a_texCoordOrig; \
			}");
	};
	return shader;
}
*/

static GLuint glow_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision mediump float; \n#endif\n"\
				"varying vec2 v_texCoord; uniform sampler2D u_texture; uniform vec3 u_color;\n"\
				"void main() {"\
					"gl_FragColor = vec4(u_color,texture2D(u_texture,v_texCoord).a);"\
				"}");
	};
	return shader;
};

static const prg_t* glow_program() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),glow_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
			prg.uniforms[0] = glGetUniformLocation(prg.prg, "u_color");
		}
	} else glUseProgram(prg.prg);
	return &prg;
}

static GLuint final_glow_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision mediump float; \n#endif\n"\
				"varying vec2 v_texCoord; uniform sampler2D u_texture; uniform float u_strength;\n"\
				"void main() {"\
					"vec4 color = texture2D(u_texture,v_texCoord);\n"\
					"color.a *= u_strength;\n"\
					"gl_FragColor = color;"\
				"}");
	};
	return shader;
};


static const prg_t* final_glow_program() {
	static prg_t prg = {0,{0,0,0}};
	if (prg.prg == 0) {
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),final_glow_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
			prg.uniforms[0] = glGetUniformLocation(prg.prg,"u_strength");
		}
	} else glUseProgram(prg.prg);
	return &prg;
}

static GLuint glow2_fragment_shader() {
	static GLuint shader = 0;
	if (shader == 0) {
		shader = compile_shader(GL_FRAGMENT_SHADER,
				"#ifdef GL_ES\nprecision mediump float; \n#endif\n"\
				"varying vec2 v_texCoord; uniform sampler2D u_texture; uniform int u_twidth; uniform int u_theight; uniform vec3 u_gcolor; uniform float u_strength;\n"\
				"void main() {"\
					"float px = 1. / float(u_twidth);"\
					"float py = 1. / float(u_theight);"\
					"float a = texture2D(u_texture,v_texCoord + vec2(-px,-py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(0,-py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(px,-py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(px,0)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(px,py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(0,py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(-px,py)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord + vec2(-px,0)).a * 0.05;"\
					"a += texture2D(u_texture,v_texCoord).a * 0.6;"\
					"gl_FragColor = vec4(u_gcolor,a * u_strength);"
				"}");
	};
	return shader;
					//"gl_FragColor = vec4(u_gcolor,a * float(u_strength));"
};

static const prg_t* glow2_program() {
	static prg_t prg = {0,{0,0,0,0}};
	if (prg.prg == 0) {
		char *attribs[2] = {"a_position","a_texCoord"};
		prg.prg = create_program(simple_vertex_shader(),glow2_fragment_shader(),2,attribs);
		if (prg.prg) {
			glUseProgram(prg.prg);
			glUniform1i(glGetUniformLocation(prg.prg,"u_texture"),0);
			prg.uniforms[0] = glGetUniformLocation(prg.prg,"u_gcolor");
			prg.uniforms[1] = glGetUniformLocation(prg.prg,"u_strength");
			prg.uniforms[2] = glGetUniformLocation(prg.prg,"u_twidth");
			prg.uniforms[3] = glGetUniformLocation(prg.prg,"u_theight");
		}
	} else glUseProgram(prg.prg);
	return &prg;
}


/*
struct glowData 
{
	color3F color;
	GLfloat strength;
};

static void glowFilter(sprogram *sp,void *data) {
	struct glowData *d = (struct glowData*)data;
	glUniform3f(sp->uniforms[1],d->color.r,d->color.g,d->color.b);
	glUniform1f(sp->uniforms[2],d->strength);
}
*/

/*
static void glowFilterFinalize(void *data) {
	struct glowData *d = (struct glowData*)data;
	caml_stat_free(d);
}
*/

/*
value ml_filter_glow(value color, value strength) { struct glowData *gd = (struct glowData*)caml_stat_alloc(sizeof(struct glowData));
	gd->color = COLOR3F_FROM_INT(Long_val(color));
	gd->strength = (GLfloat)Long_val(strength);
	return make_filter(&glowFilter,&glowFilterFinalize,gd);
}
*/


static inline GLuint powOfTwo(unsigned int p) {
	GLuint r = 1;
	for (unsigned int i = 0; i < p; i++) {
		r *= 2;
	}
	return r;
}

void ml_glow2_make(value orb,value glow) {
	renderbuffer_t *rb = (renderbuffer_t*)Field(orb,0);
	int gsize = Int_val(Field(glow,0));
	color3F c = COLOR3F_FROM_INT(Int_val(Field(glow,1)));

	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	lgResetBoundTextures();
	setNotPMAGLBlend ();
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);

	glClearColor(0.,0.,0.,0.);
	const prg_t *prg = glow2_program();
	glUniform3f(prg->uniforms[0],c.r,c.g,c.b);
	glUniform1i(prg->uniforms[1],Double_val(Field(glow,2)));
	glUniform1i(prg->uniforms[2],rb->width);
	glUniform1i(prg->uniforms[3],rb->height);
	checkGLErrors("glow2 bind uniforms");

	renderbuffer_t rb2;
	create_renderbuffer(rb->width,rb->height,&rb2,GL_NEAREST); // м.б. clone
	renderbuffer_t *drb = &rb2;
	renderbuffer_t *srb = rb;
	renderbuffer_t *trb;
	for (int i=0;i<gsize;i++) {
		drawRenderbuffer(drb,srb,1);
		trb = drb; drb = srb; srb = trb;
	};
	// и вот здесь вопрос чего вернуть
	glBindTexture(GL_TEXTURE_2D,0);
	if (srb->fbid != rb->fbid) {
		fprintf(stderr,"we need return new texture\n");
		// бля не повезло надо бы тут пошаманить
		// Ебнуть текстуру старую и перезаписать в ml ную структуру
		update_texture_id(Field(Field(orb,1),0),rb2.tid);
		delete_renderbuffer(rb);
		rb->tid = rb2.tid;
		rb->fbid = rb2.fbid;
		fstate.framebuffer = rb->fbid;
	} else delete_renderbuffer(&rb2);
	glUseProgram(0);
	currentShaderProgram = 0;
	checkGLErrors("glow make finished");
	set_framebuffer_state(&fstate);
	checkGLErrors("framebuffer state back after make glow");
}

static void inline glow_make_draw(GLuint w,GLuint h) {
	static GLfloat quads[4][2] = {{-1.,-1.},{1.,-1.},{-1.,1.},{1.,1.}};
	static GLfloat texCoords[4][2] = {{0.,0.},{1.,0.},{0.,1.},{1.,1.}};
	glViewport(0,0,w,h);
	glClear(GL_COLOR_BUFFER_BIT);
	glVertexAttribPointer(lgVertexAttrib_Position,2,GL_FLOAT,GL_FALSE,0,quads);
	glVertexAttribPointer(lgVertexAttrib_TexCoords,2,GL_FLOAT,GL_FALSE,0,texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void ml_glow_make(value orb, value glow) {
	checkGLErrors("start make glow");
	int gsize = Int_val(Field(glow,0));
	renderbuffer_t *rb = (renderbuffer_t*)Field(orb,0);

	fprintf(stderr,"create glow %d - [%f:%f]\n",gsize,rb->width,rb->height);

	//int pma = Bool_val(Field(kind,0));

	lgResetBoundTextures();
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	glDisable(GL_BLEND);
	glClearColor(0.,0.,0.,0.);

	const prg_t *glowPrg = glow_program();
	color3F c = COLOR3F_FROM_INT(Int_val(Field(glow,1)));
	glUniform3f(glowPrg->uniforms[0],c.r,c.g,c.b);

	GLuint *txrs = caml_stat_alloc(gsize * sizeof(GLuint));
  glGenTextures(gsize, txrs);
	GLuint *bfrs = caml_stat_alloc(gsize * sizeof(GLuint));
	glGenFramebuffers(gsize, bfrs);

	int i;
	GLuint w = rb->realWidth;
	GLuint h = rb->realHeight;
	GLuint ctid = rb->tid;
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);
	for (i = 0; i < gsize; i++) {
		w /= 2;
		h /= 2;
		glBindTexture(GL_TEXTURE_2D, txrs[i]);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
		glBindFramebuffer(GL_FRAMEBUFFER, bfrs[i]);
		glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, txrs[i],0);
		/*if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			PRINT_DEBUG("framebuffer %d status: %d\n",fbid,glCheckFramebufferStatus(GL_FRAMEBUFFER));
			return NULL;
		};*/
		glBindTexture(GL_TEXTURE_2D,ctid);
		glow_make_draw(w,h);
		ctid = txrs[i];
		checkGLErrors("draw forward");
	};

	GLuint cbuf;
	for (i = gsize - 1; i > 0 ; i--) {
		w *= 2;
		h *= 2;
		cbuf = bfrs[i-1];
		glBindFramebuffer(GL_FRAMEBUFFER,cbuf);
		ctid = txrs[i];
		glBindTexture(GL_TEXTURE_2D,ctid);
		glow_make_draw(w,h);
	};
	// и теперь с блэндингом нахуй 
	glEnable(GL_BLEND);
	setNotPMAGLBlend (); // WARNING - ensure what separate blend enabled
	const prg_t *fglowPrg = final_glow_program();
	glUniform1f(fglowPrg->uniforms[0],Double_val(Field(glow,2)));
	checkGLErrors("final glow program");
	glBindFramebuffer(GL_FRAMEBUFFER,rb->fbid);
	glBindTexture(GL_TEXTURE_2D,txrs[0]);
	glow_make_draw(rb->realWidth,rb->realHeight);

	glDeleteFramebuffers(gsize,bfrs);
	caml_stat_free(bfrs);
	glDeleteTextures(gsize,txrs);
	caml_stat_free(txrs);

	glBindTexture(GL_TEXTURE_2D,0);
	glUseProgram(0);
	currentShaderProgram = 0;
	checkGLErrors("glow make finished");
	set_framebuffer_state(&fstate);
	checkGLErrors("framebuffer state back after make glow");

	/*
	renderbuffer_t ib;
	create_renderbuffer(rwidth/2,rheight/2,&ib,GL_LINEAR);
	GLuint tid = TEXTURE_ID(Field(textureInfo,0));
	value clip = Field(textureInfo,3);
	clipping clp;
	if (clip != 1) {
		value c = Field(clip,0);
		clp.x = Double_field(c,0);
		clp.y = Double_field(c,1);
		clp.width = Double_field(c,2);
		clp.height = Double_field(c,3);
	} else { 
		clp.x = 0;
		clp.y = 0;
		clp.width = 1.;
		clp.height = 1.;
	};
	glBindTexture(GL_TEXTURE_2D,tid);
	*/
	/*GLint filter;
	glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,&filter);
	fprintf(stderr,"filter: %x\n",filter);
	if (filter != GL_LINEAR) {
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	};
	*/
	//drawTexture(&ib,tid,ib->width,ib->height,&clp,1);
	/*if (filter != GL_LINEAR) {
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,filter);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,filter);
	};*/
	/*
	if (gsize > 1) {
		renderbuffer_t *crb = &ib;
		renderbuffer_t *rbfs;
		rbfs = caml_stat_alloc(gsize*sizeof(renderbuffer_t));
		int i;
		double w = ib.width, h = ib.height;
		renderbuffer_t *prb;
		for (i = 0; i < gsize - 1; i++) {
			w /= 2;
			h /= 2;
			prb = rbfs + i;
			create_renderbuffer(w,h,prb,GL_LINEAR);
			checkGLErrors("create renderbuffer");
			PRINT_DEBUG("draw forward %i",i);
			drawTexture(prb, crb->tid, w, h, &crb->clp,1);
			crb = prb;
			checkGLErrors("draw forward");
		};
		for (i = gsize - 2; i > 0 ; i--) {
			prb = rbfs + i;
			crb = prb - 1;
			PRINT_DEBUG("draw back %i",i);
			drawTexture(crb,prb->tid,crb->width,crb->height,&prb->clp,1);
			checkGLErrors("draw back");
			delete_renderbuffer(prb);
		};
		drawTexture(&ib,crb->tid,ib.width,ib.height,&crb->clp,1);
		delete_renderbuffer(crb);
		caml_stat_free(rbfs);
	};
	*/

	// теперь новое... нужно создать новый буфер и туда насрать ib и поверх оригирал с блендингом 
	/*renderbuffer_t rb;
	create_renderbuffer(rwidth,rheight,&rb,GL_NEAREST);
	*/
	/*glEnable(GL_BLEND);
	glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
	GLuint fglowPrg = final_glow_program();
	glUseProgram(fglowPrg);
	glUniform1i(glGetUniformLocation(fglowPrg,"u_strength"),Long_val(Field(glow,2)));

	//glClearColor(1.,1.,1.,0.);
	drawTexture(&rb,ib.tid,rwidth,rheight,&ib.clp,1);
	delete_renderbuffer(&ib);
	checkGLErrors("draw blurred");

	*/

	// делаем activate и заворачивалку с 'c' rendered текстур и пиздиец
	// а потом с хитрым шейдером еще разок, сравниваем префоманс - и чего-то уже решаем 

	//glEnable(GL_BLEND);

	/*
	if (pma) glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA); 
	else glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);

	GLuint simplePrg = simple_program();
	glUseProgram(simplePrg);
	drawTexture(&ib,tid,iwidth,iheight,&clp,0);
	*/


	/*value res = create_ml_texture(&ib);
	glDeleteFramebuffers(1,&ib.fbid);

	glBindTexture(GL_TEXTURE_2D,0);
	glBindFramebuffer(GL_FRAMEBUFFER,0); 
	glUseProgram(0);
	currentShaderProgram = 0;
	checkGLErrors("glow make finished");
	set_framebuffer_state(&fstate);
	checkGLErrors("framebuffer state back after make glow");
	return res;*/
}

/*
void ml_glow_make2_byte(value * argv, int n) {
	ml_glow_make2(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5]);
}
*/

/*
void ml_glow_make(value framebufferID, value textureID, value twidth, value theight, value clip, value sourceTexture, value count) {
	renderbuffer_t tb;
	// здесь хитрый изъеб - но так быстрее нах.  
	tb.fbid = Long_val(framebufferID);
	tb.tid = Long_val(textureID);
	tb.width = Double_val(twidth);
	tb.height = Double_val(theight);
	if (clip != 1) {
		value c = Field(clip,0);
		tb.clp.x = Double_field(c,0);
		tb.clp.y = Double_field(c,1);
		tb.clp.width = Double_field(c,2);
		tb.clp.height = Double_field(c,3);
	} else { 
		tb.clp.x = 0;
		tb.clp.y = 0;
		tb.clp.width = 1.;
		tb.clp.height = 1.;
	};

	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	glDisable(GL_BLEND);
	glClearColor(0.,0.,0.,0.);
	GLuint glowPrg = glow_program();
	glUseProgram(glowPrg);

	if (sourceTexture != 1) {
		value st = Field(sourceTexture,0);
		GLuint tid = Long_val(Field(st,0));
		double w = Double_val(Field(st,1));
		double h = Double_val(Field(st,2));
		value clip = Field(st,3);
		clipping clp;
		if (clip != 1) {
			value c = Field(clip,0);
			clp.x = Double_field(c,0);
			clp.y = Double_field(c,1);
			clp.width = Double_field(c,2);
			clp.height = Double_field(c,3);
		} else { 
			clp.x = 0;
			clp.y = 0;
			clp.width = 1.;
			clp.height = 1.;
		};
		drawTexture(&tb,tid,w/2,h/2,&clp,1);
	};

	int gsize = Int_val(count);

	PRINT_DEBUG("make glow of size %d",gsize);
	if (gsize > 1) {
		renderbuffer_t *crb = &tb;
		renderbuffer_t *rbfs;
		rbfs = caml_stat_alloc((gsize - 1)*sizeof(renderbuffer_t));
		int i;
		double w = tb.width, h = tb.height;
		renderbuffer_t *prb;
		for (i = 0; i < gsize - 1; i++) {
			w /= 2;
			h /= 2;
			prb = rbfs + i;
			create_renderbuffer(w,h,prb);
			checkGLErrors("create renderbuffer");
			PRINT_DEBUG("draw forward %i",i);
			drawTexture(prb, crb->tid, crb->width / 2, crb->height / 2, &crb->clp,1);
			crb = prb;
			checkGLErrors("draw forward");
		};
		for (i = gsize - 1; i > 1 ; i--) {
			prb = rbfs + i;
			crb = rbfs - 1;
			PRINT_DEBUG("draw back %i",i);
			drawTexture(crb,prb->tid,prb->width,prb->height,&prb->clp,1);
			checkGLErrors("draw back");
			delete_renderbuffer(prb);
		};
		drawTexture(&tb,crb->tid,tb.width,tb.height,&crb->clp,1);
		delete_renderbuffer(crb);
		caml_stat_free(rbfs);
	};
	glBindTexture(GL_TEXTURE_2D,0);
	glBindFramebuffer(GL_FRAMEBUFFER,0); 
	glUseProgram(0);
	boundTextureID = 0;
	currentShaderProgram = 0;
	set_framebuffer_state(&fstate);
	glEnable(GL_BLEND);
}


void ml_glow_make_byte(value * argv, int n) {
	ml_glow_make(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5],argv[6]);
}
*/


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
