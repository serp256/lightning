
#include "texture_common.h"
#include "render_stub.h"
#include <caml/callback.h>
#include "math.h"
#include "renderbuffer_stub.h"
#include "inline_shaders.h"

extern GLuint currentShaderProgram;

/*typedef struct {
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
}*/

/*
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
*/

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

static int filter_compare(value fltr1,value fltr2) {
	filter *f1 = FILTER(fltr1);
	filter *f2 = FILTER(fltr2);
	if (f1 == f2) return 0;
	else {
		if (f1 < f2) return -1;
		return 1;
	}
}

struct custom_operations filter_ops = {
  "pointer to a filter",
  filter_finalize,
	filter_compare,
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

/*static GLuint glow_fragment_shader() {
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
			prg.uniforms[1] = glGetUniformLocation(prg.prg,"u_twidth");
			prg.uniforms[2] = glGetUniformLocation(prg.prg,"u_theight");
			prg.uniforms[3] = glGetUniformLocation(prg.prg,"u_strength");
			glUniform1f(prg.uniforms[3],1.);
		}
	} else glUseProgram(prg.prg);
	return &prg;
}*/


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


/*
static inline GLuint powOfTwo(unsigned int p) {
	GLuint r = 1;
	unsigned int i;
	for (i = 0; i < p; i++) {
		r *= 2;
	}
	return r;
}
*/

value ml_glow2_make(value orb,value glow) {
	renderbuffer_t *rb = (renderbuffer_t*)orb;
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
	glUniform1i(prg->uniforms[1],rb->width);
	glUniform1i(prg->uniforms[2],rb->height);
	double strength = Double_val(Field(glow,2)); 
	/*double sk = strength > 1. ? 1. : strength;
	fprintf(stderr,"sk: %f, %f\n", sk, sk/ 8.);
	glUniform1f(prg->uniforms[3],sk / 8.);
	glUniform1f(prg->uniforms[4],1. - sk);
	glUniform1f(prg->uniforms[5],1.); */
	checkGLErrors("bind glow uniforms");

	renderbuffer_t rb2;
	// clone_renderbuffer(rb,&rb2,GL_NEAREST); // м.б. clone
	renderbuffer_t *drb = &rb2;
	renderbuffer_t *srb = rb;
	renderbuffer_t *trb;
	int i;
	for (i=0;i<gsize;i++) {
		if (strength != 1. && i == (gsize - 1)) glUniform1f(prg->uniforms[3],strength);
		drawRenderbuffer(drb,srb,1);
		trb = drb; drb = srb; srb = trb;
	};
	if (strength != 1.) glUniform1f(prg->uniforms[3],1.);
	// и вот здесь вопрос чего вернуть
	glBindTexture(GL_TEXTURE_2D,0);
	if (srb->fbid != rb->fbid) {
		//fprintf(stderr,"we need return new texture\n");
		// бля не повезло надо бы тут пошаманить
		// Ебнуть текстуру старую и перезаписать в ml ную структуру
		//update_texture_id(Field(Field(orb,1),0),rb2.tid);
		delete_renderbuffer(rb);
		rb->tid = rb2.tid;
		rb->fbid = rb2.fbid;
		fstate.framebuffer = rb->fbid;
	} else delete_renderbuffer(&rb2);
	glUseProgram(0);
	currentShaderProgram = 0;
	set_framebuffer_state(&fstate);
	return Val_unit;
}

static void inline glow_make_draw(viewport *vp,clipping *clp, int clear) {
	glViewport(vp->x,vp->y,vp->w,vp->h);
	if (clear) glClear(GL_COLOR_BUFFER_BIT);

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

struct vpclp {
	viewport vp;
	clipping clp;
};

static GLuint maxFB = 20;
static GLuint txrs[12][12] = {{0}};
static GLuint* bfrs = NULL;
static inline GLuint powS( GLuint l )
{
	if ( l == 1 ) return 0;
	if ( l == 2 ) return 1;
	if ( l == 4 ) return 2;
	if ( l == 8 ) return 3;
	if ( l == 16 ) return 4;
	if ( l == 32 ) return 5;
	if ( l == 64 ) return 6;
	if ( l == 128 ) return 7;
	if ( l == 256 ) return 8;
	if ( l == 512 ) return 9;
	if ( l == 1024 ) return 10;
	if ( l == 2048 ) return 11;
//	if ( l == 4096 ) return 12;
//	if ( l == 8192 ) return 13;
	char errmsg[255];
	sprintf(errmsg,"wrong texture size %d", l);
	caml_failwith(errmsg);
	return 0;
};

static save_tex_cnt = 0;
static glow_tex_cnt = 0;

void draw_glow_level(GLuint w, GLuint h, GLuint frm_buf_id, GLuint* prev_glow_lev_tex, viewport* vp, clipping* clp, int bind) {
	PRINT_DEBUG("draw_glow_level %f %f %f %f", clp->x, clp->y, clp->width, clp->height);

	int tw = powS(w);
	int th = powS(h);

	if (txrs[tw][th] == 0) {
		glGenTextures(1, &(txrs[tw][th]));
		glBindTexture(GL_TEXTURE_2D, txrs[tw][th]);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	}

	glBindFramebuffer(GL_FRAMEBUFFER, frm_buf_id);

	if (bind) {
		glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, txrs[tw][th], 0);
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			char errmsg[255];
			sprintf(errmsg,"glow make. bind framebuffer %d to texture, %d:%d status: %X",frm_buf_id,w,h,glCheckFramebufferStatus(GL_FRAMEBUFFER));
			caml_failwith(errmsg);
		}
	}

	glBindTexture(GL_TEXTURE_2D, *prev_glow_lev_tex);
	glow_make_draw(vp, clp, 1);
	*prev_glow_lev_tex = txrs[tw][th];

/*	//------------------
	char* pixels = caml_stat_alloc(4 * (GLuint)w * (GLuint)h);
	char* fname = malloc(255);
	sprintf(fname, "/sdcard/pizda%04d.png", save_tex_cnt++);
	glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	save_png_image(caml_copy_string(fname),pixels,w,h);
	//------------------*/

	if (!bind) {
		glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);	
	}
}

value ml_glow_make(value orb, value glow) {
	int gsize = Int_val(Field(glow,0));
	if (gsize == 0) return ;
	renderbuffer_t *rb = (renderbuffer_t *)orb;

	int rectw = rb->realWidth;
	int recth = rb->realHeight;
	viewport rbvp = { rb->vp.x - (rectw - rb->vp.w) / 2, rb->vp.y - (recth - rb->vp.h) / 2, rectw, recth };

	double texw = rb->vp.w / rb->clp.width;
	double texh = rb->vp.h / rb->clp.height;
	PRINT_DEBUG("texw %f, texh %f", texw, texh);
	clipping rbclp = { (GLfloat)rbvp.x / texw, (GLfloat)rbvp.y / texh, (GLfloat)rbvp.w  / texw, (GLfloat)rbvp.h  / texh };

	PRINT_DEBUG("!!!!!! vp: [%d, %d, %d, %d] clp: [%f, %f, %f, %f]", rbvp.x, rbvp.y, rbvp.w, rbvp.h, rbclp.x, rbclp.y, rbclp.width, rbclp.height);

	glBindFramebuffer(GL_FRAMEBUFFER, rb->fbid);

/*	char* pixels = caml_stat_alloc(4 * (GLuint)rbvp.w * (GLuint)rbvp.h);
	char* fname = malloc(255);
	sprintf(fname, "/sdcard/pizda%04d.png", save_tex_cnt++);
	glReadPixels(0,0,rbvp.w,rbvp.h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	save_png_image(caml_copy_string(fname),pixels,rbvp.w,rbvp.h);*/

	checkGLErrors("end of glow");

/*	PRINT_DEBUG("save_tex_cnt %d", save_tex_cnt);
	PRINT_DEBUG("glow make for %d:%d, [%f:%f] [%d:%d]",rb->fbid,rb->tid,rb->width,rb->height,rb->realWidth,rb->realHeight);*/

	lgResetBoundTextures();
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	glDisable(GL_BLEND);
	glClearColor(0.,0.,0.,0.);

	const prg_t *glowPrg = glow_program();
	color3F c = COLOR3F_FROM_INT(Int_val(Field(glow,1)));
	glUniform3f(glowPrg->uniforms[0],c.r,c.g,c.b);

	if (bfrs == NULL) // можно пооптимальней это сделать
	{
		bfrs = caml_stat_alloc(maxFB * sizeof(GLuint));
		glGenFramebuffers(maxFB, bfrs);
	}

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);

	int i;
	float glow_lev_w = rectw;
	float glow_lev_h = recth;
	int iglow_lev_w;
	int iglow_lev_h;
	GLuint correct_lev_w;
	GLuint correct_lev_h;
	GLuint prev_glow_lev_tex = rb->tid;

	GLuint fst_scalein_tex_id = 0;
	viewport* vp;
	clipping* clp = &rbclp;
	viewport vps[gsize];
	clipping clps[gsize];

	for (i = 0; i < gsize; i++) {		
		glow_lev_w /= 2;
		glow_lev_h /= 2;

		iglow_lev_w = (int)ceil(glow_lev_w);
		iglow_lev_h = (int)ceil(glow_lev_h);

		PRINT_DEBUG("glow_lev_w %f, glow_lev_h %f", glow_lev_w, glow_lev_h);
		correct_lev_w = nextPOT(iglow_lev_w);
		correct_lev_h = nextPOT(iglow_lev_h);
		PRINT_DEBUG("correct_lev_w %d, correct_lev_h %d", correct_lev_w, correct_lev_h);
		TEXTURE_SIZE_FIX(correct_lev_w, correct_lev_h);

		vp = &vps[i];
		vp->x = (correct_lev_w - iglow_lev_w) / 2; vp->y = (correct_lev_h - iglow_lev_h) / 2; vp->w = iglow_lev_w; vp->h = iglow_lev_h;

		draw_glow_level(correct_lev_w, correct_lev_h, bfrs[i], &prev_glow_lev_tex, vp, clp, 1);
		if (!fst_scalein_tex_id) fst_scalein_tex_id = prev_glow_lev_tex;
		
		clp = &clps[i];
		clp->x = (GLfloat)vp->x / correct_lev_w; clp->y = (GLfloat)vp->y / correct_lev_h; clp->width = (GLfloat)iglow_lev_w / correct_lev_w; clp->height = (GLfloat)iglow_lev_h / correct_lev_h;
	}

	for (i = gsize - 1; i > 0; i--) {
		glow_lev_w *= 2;
		glow_lev_h *= 2;

		iglow_lev_w = (int)ceil(glow_lev_w);
		iglow_lev_h = (int)ceil(glow_lev_h);

		PRINT_DEBUG("glow_lev_w %f, glow_lev_h %f", glow_lev_w, glow_lev_h);
		correct_lev_w = nextPOT(iglow_lev_w);
		correct_lev_h = nextPOT(iglow_lev_h);
		PRINT_DEBUG("correct_lev_w %d, correct_lev_h %d", correct_lev_w, correct_lev_h);
		TEXTURE_SIZE_FIX(correct_lev_w, correct_lev_h);
		draw_glow_level(correct_lev_w, correct_lev_h, bfrs[i - 1], &prev_glow_lev_tex, &vps[i - 1], &clps[i], 0);
	}

	glEnable(GL_BLEND);
	setNotPMAGLBlend (); // WARNING - ensure what separate blend enabled
	const prg_t *fglowPrg = final_glow_program();
	glUniform1f(fglowPrg->uniforms[0],Double_val(Field(glow,2)));
	glBindFramebuffer(GL_FRAMEBUFFER, rb->fbid);
	glBindTexture(GL_TEXTURE_2D, fst_scalein_tex_id);

	glow_make_draw(&rbvp, clps, 0);

/*	pixels = caml_stat_alloc(4 * (GLuint)rbvp.w * (GLuint)rbvp.h);
	fname = malloc(255);
	sprintf(fname, "/sdcard/pizda%04d.png", save_tex_cnt++);
	glReadPixels(rbvp.x,rbvp.y,rbvp.w,rbvp.h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	save_png_image(caml_copy_string(fname),pixels,rbvp.w,rbvp.h);	*/

	glBindTexture(GL_TEXTURE_2D,0);
	glUseProgram(0);
	currentShaderProgram = 0;
	set_framebuffer_state(&fstate);
	checkGLErrors("end of glow");

	return Val_unit;
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
	GLfloat *data = malloc(sizeof(GLfloat) * 20);
	int i;
	for (i = 0; i < 20; i++) {
		data[i] = Double_field(matrix,i);
	};
	return make_filter(&colorMatrixFilter,free,data);
}
