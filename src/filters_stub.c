
#include "texture_common.h"
#include "render_stub.h"
#include <caml/callback.h>
#include "math.h"
#include "inline_shaders.h"
#include "rendertex/common.h"

extern GLuint currentShaderProgram;

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
	texCoords[1][0] = clp->x + clp->w;
	texCoords[1][1] = clp->y;
	texCoords[2][0] = clp->x;
	texCoords[2][1] = clp->y + clp->h;
	texCoords[3][0] = texCoords[1][0];
	texCoords[3][1] = texCoords[2][1];
	glVertexAttribPointer(lgVertexAttrib_Position,2,GL_FLOAT,GL_FALSE,0,quads);
	glVertexAttribPointer(lgVertexAttrib_TexCoords,2,GL_FLOAT,GL_FALSE,0,texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

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

value ml_glow2_make(value orb,value glow) {
	renderbuffer_t *rb = (renderbuffer_t*)orb;
	int gsize = Int_val(Field(glow,0));
	color3F c = COLOR3F_FROM_INT(Int_val(Field(glow,1)));

/*	framebuffer_state fstate;
	get_framebuffer_state(&fstate);*/
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

/*	if (srb->fbid != rb->fbid) {
		//fprintf(stderr,"we need return new texture\n");
		// бля не повезло надо бы тут пошаманить
		// Ебнуть текстуру старую и перезаписать в ml ную структуру
		//update_texture_id(Field(Field(orb,1),0),rb2.tid);
		delete_renderbuffer(rb);
		rb->tid = rb2.tid;
		rb->fbid = rb2.fbid;
		// fstate.framebuffer = rb->fbid;
	} else delete_renderbuffer(&rb2);*/
		
	glUseProgram(0);
	currentShaderProgram = 0;
	// set_framebuffer_state(&fstate);
	return Val_unit;
}

static void inline glow_make_draw(clipping *clp, int clear) {
	if (clear) glClear(GL_COLOR_BUFFER_BIT);

	texCoords[0][0] = clp->x;
	texCoords[0][1] = clp->y;
	texCoords[1][0] = clp->x + clp->w;
	texCoords[1][1] = clp->y;
	texCoords[2][0] = clp->x;
	texCoords[2][1] = clp->y + clp->h;
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


#define INIT_BUFFERS if (bfrs == NULL) { bfrs = caml_stat_alloc(maxFB * sizeof(GLuint)); glGenFramebuffers(maxFB, bfrs); }
#define INIT_TEX(w, h, tw, th)  															\
	tw = powS(w);																			\
	th = powS(h);																			\
	if (txrs[tw][th] == 0) { 																\
		glGenTextures(1, &(txrs[tw][th]));													\
		glBindTexture(GL_TEXTURE_2D, txrs[tw][th]);											\
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);					\
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);					\
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);				\
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);				\
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);	\
	}

// static int xyu = 0;

void draw_glow_level(GLuint w, GLuint h, GLuint* prev_glow_lev_tex, clipping* clp, uint8_t mag) { //mag means magnification; when minifying we should bind texture to framebuffer and unbind when magnifying
	PRINT_DEBUG("draw_glow_level clipping %f %f %f %f; prev_glow_lev_tex %d", clp->x, clp->y, clp->w, clp->h, *prev_glow_lev_tex);

	int tw, th;
	INIT_TEX(w, h, tw, th);

	if (!mag) {
		glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, txrs[tw][th], 0);
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			char errmsg[255];
			sprintf(errmsg,"glow make. bind framebuffer, %d:%d status: %X", w, h, glCheckFramebufferStatus(GL_FRAMEBUFFER));
			caml_failwith(errmsg);
		}
	}

	// char fname[100];
	// sprintf(fname, "/sdcard/%.4d.png", xyu);


	glBindTexture(GL_TEXTURE_2D, *prev_glow_lev_tex);
/*	GLint _w, _h;
	glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &_w);
	glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &_h);
	PRINT_DEBUG("TEXTURE %d params %d;%d", *prev_glow_lev_tex, _w, _h);
	void *pixels = malloc(_w * _h * 4);
	glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
	save_png_image(fname, pixels, (unsigned int)_w, (unsigned int)_h);*/


	glow_make_draw(clp, 1);
	*prev_glow_lev_tex = txrs[tw][th];

/*	sprintf(fname, "/sdcard/%.4d.png", xyu + 1);
	renderbuf_save_current(caml_copy_string(fname));
	xyu += 10;*/

	if (mag < 0) {
		glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);	
	}
}

value ml_glow_make(value orb, value glow) {
	int gsize = Int_val(Field(glow,0));
	if (gsize == 0) return Val_unit;
	renderbuffer_t *rb = (renderbuffer_t *)orb;

	int rectw = rb->realWidth;
	int recth = rb->realHeight;
	viewport rbvp = { rb->vp.x - (rectw - rb->vp.w) / 2, rb->vp.y - (recth - rb->vp.h) / 2, rectw, recth };

	double texw = rb->vp.w / rb->clp.w;
	double texh = rb->vp.h / rb->clp.h;
	clipping rbclp = { (GLfloat)rbvp.x / texw, (GLfloat)rbvp.y / texh, (GLfloat)rbvp.w  / texw, (GLfloat)rbvp.h  / texh };

	/* at a glance no need in this call, but it is important:
		first, it guarantees needed framebuffer id will be setted (generally it is already setted)
		second, it applies viewport differ than default when poping from stack
	*/
	framebuf_push(rb->fbid, &rbvp, FRAMEBUF_APPLY_BUF);

/*	char fname[100];
	sprintf(fname, "/sdcard/%.4d.png", xyu);
	xyu += 10;
	renderbuf_save_current(caml_copy_string(fname));*/

	lgResetBoundTextures();
	glDisable(GL_BLEND);
	glClearColor(0.,0.,0.,0.);

	const prg_t *glowPrg = glow_program();
	color3F c = COLOR3F_FROM_INT(Int_val(Field(glow,1)));
	glUniform3f(glowPrg->uniforms[0],c.r,c.g,c.b);
	INIT_BUFFERS;
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);

	int i;
	float glow_w = rectw;
	float glow_h = recth;
	int iglow_w;
	int iglow_h;
	GLuint glow_texw;
	GLuint glow_texh;
	GLuint prev_glow_lev_tex = rb->tid;

	GLuint backtobuf_tid = 0; // texture from which we draw back into renderbuffer after sequential minifying/magnifying 
	clipping *clp = &rbclp;
	clipping clps[gsize];

	for (i = 0; i < gsize; i++) {		
		glow_w /= 2;
		glow_h /= 2;

		iglow_w = (int)ceil(glow_w);
		iglow_h = (int)ceil(glow_h);

		glow_texw = nextPOT(iglow_w);
		glow_texh = nextPOT(iglow_h);
		TEXTURE_SIZE_FIX(glow_texw, glow_texh);

		viewport vp = (viewport) { (glow_texw - iglow_w) / 2, (glow_texh - iglow_h) / 2, iglow_w, iglow_h };
		framebuf_push(bfrs[i], &vp, FRAMEBUF_APPLY_ALL);
		draw_glow_level(glow_texw, glow_texh, &prev_glow_lev_tex, clp, 0);
		if (!backtobuf_tid) backtobuf_tid = prev_glow_lev_tex;
		clp = &clps[i];
		clp->x = (GLfloat)vp.x / glow_texw;
		clp->y = (GLfloat)vp.y / glow_texh;
		clp->w = (GLfloat)vp.w / glow_texw;
		clp->h = (GLfloat)vp.h / glow_texh;
	}

	for (i = gsize - 1; i > 0; i--) {
		glow_w *= 2;
		glow_h *= 2;
		glow_texw = nextPOT((GLuint)glow_w);
		glow_texh = nextPOT((GLuint)glow_h);
		TEXTURE_SIZE_FIX(glow_texw, glow_texh);

		framebuf_pop();
		draw_glow_level(glow_texw, glow_texh, &prev_glow_lev_tex, &clps[i], 1);
	}

	glEnable(GL_BLEND);
	setNotPMAGLBlend (); // WARNING - ensure what separate blend enabled
	const prg_t *fglowPrg = final_glow_program();
	glUniform1f(fglowPrg->uniforms[0], Double_val(Field(glow,2)));
	glBindTexture(GL_TEXTURE_2D, backtobuf_tid);

	framebuf_pop(); //this call pops our renderbuffer this unusual viewport 
	PRINT_DEBUG("final clipping %f %f %f %f", clps->x, clps->y, clps->w, clps->h);
	glow_make_draw(clps, 0);
	glBindTexture(GL_TEXTURE_2D, 0);
	glUseProgram(0);
	currentShaderProgram = 0;
	checkGLErrors("end of glow");
	framebuf_pop(); //this call finally returns to state before this function called (generally it is renderbuffer with std viewport)

	return Val_unit;
}


///////////////////
//// COLOR MATRIX
/////////////////////

typedef struct {
	GLfloat matrix[20];
	GLfloat color[4];
} strokecolormatrix_t;

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

value ml_filter_cmatrix_extract(value vfilter) {
	CAMLparam1(vfilter);
	CAMLlocal1(retval);

	filter* f = FILTER(vfilter);
	GLfloat* data = (GLfloat*)f->data;
	retval = caml_alloc(20 * Double_wosize, Double_array_tag);
	int i;
	for (i = 0; i < 20; i++) {
		Store_double_field(retval, i, *(data + i));
	}

	CAMLreturn(retval);
}

static void strokeFilter(sprogram* sp, void* data) {
	glUniform4fv(sp->uniforms[1], 1, (GLfloat*)data);
}

value ml_filter_stroke(value vcolor) {
	GLfloat* data = malloc(sizeof(GLfloat) * 4);
	int color = Int_val(vcolor);

	*data = (GLfloat)COLOR_PART_RED(color) / 255.;
	*(data + 1) = (GLfloat)COLOR_PART_GREEN(color) / 255.;
	*(data + 2) = (GLfloat)COLOR_PART_BLUE(color) / 255.;
	*(data + 3) = (GLfloat)COLOR_PART_ALPHA(color) / 255.;

	return make_filter(&strokeFilter, free, data);
}

static void strokeColorMatrixFilter(sprogram* sp, void* data) {
	strokecolormatrix_t* d = (strokecolormatrix_t*)data;

	glUniform4fv(sp->uniforms[1], 1, d->color);
	glUniform1fv(sp->uniforms[2], 20,d->matrix);
}

value ml_filter_strkclrmtx(value vcolor, value matrix) {
	CAMLparam2(matrix, vcolor);
	strokecolormatrix_t* data = malloc(sizeof(strokecolormatrix_t));
	int color = Int_val(vcolor);

	data->color[0] = (GLfloat)COLOR_PART_RED(color) / 255.;
	data->color[1] = (GLfloat)COLOR_PART_GREEN(color) / 255.;
	data->color[2] = (GLfloat)COLOR_PART_BLUE(color) / 255.;
	data->color[3] = (GLfloat)COLOR_PART_ALPHA(color) / 255.;

	int i;
	for (i = 0; i < 20; i++) {
		data->matrix[i] = Double_field(matrix,i);
	};

	CAMLreturn(make_filter(&strokeColorMatrixFilter, free, data));
}
