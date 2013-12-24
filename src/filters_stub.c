
#include "texture_common.h"
#include "render_stub.h"
#include <caml/callback.h>
#include "math.h"
#include "renderbuffer_stub.h"
#include "inline_shaders.h"

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

void draw_glow_level(GLuint w, GLuint h, GLuint frm_buf_id, GLuint* prev_glow_lev_tex, viewport* vp, clipping* clp, int bind) {
	PRINT_DEBUG("draw_glow_level %f %f %f %f", clp->x, clp->y, clp->width, clp->height);

	int tw, th;
	INIT_TEX(w, h, tw, th);
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

void ml_shadow_make(value orb, value shadow){
	lgResetBoundTextures();
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	glDisable(GL_BLEND);
	glClearColor(0.,0.,0.,0.);

	int size = Int_val(Field(shadow,0));
	color3F color = COLOR3F_FROM_INT(Int_val(Field(shadow,1)));
	int sx = Int_val(Field(shadow,2));
	int sy = Int_val(Field(shadow,3));

	renderbuffer_t* dst_rb = (renderbuffer_t*)orb;

	int tex_w = nextPOT(dst_rb->vp.w);
	int tex_h = nextPOT(dst_rb->vp.h);
	TEXTURE_SIZE_FIX(tex_w, tex_h);
	int tw_indx, th_indx;
	INIT_TEX(tex_w, tex_h, tw_indx, th_indx);

	INIT_BUFFERS;

	glBindFramebuffer(GL_FRAMEBUFFER, bfrs[0]);
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, txrs[tw_indx][th_indx], 0);
	checkGLErrors("binding texture to buffer");

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		char errmsg[255];
		sprintf(errmsg,"shadow make. bind framebuffer %d to texture, status: %X", dst_rb->fbid, glCheckFramebufferStatus(GL_FRAMEBUFFER));
		caml_failwith(errmsg);
	}

	glBindTexture(GL_TEXTURE_2D, dst_rb->tid);
	checkGLErrors("binding texture");

	currentShaderProgram = 0;
	prg_t* prog = shadow_vertical_blur_prog();
	checkGLErrors("program");

	float radius = (float)size;
	float width = (float)dst_rb->realWidth;
	float height = (float)tex_h;
	viewport vp = (viewport){ (tex_w - dst_rb->vp.w) / 2, (tex_h - dst_rb->vp.h) / 2, dst_rb->vp.w, dst_rb->vp.h };
	GLfloat ftex_w = (GLfloat)tex_w;
	GLfloat ftex_h = (GLfloat)tex_h;
	clipping clp = (clipping){ (GLfloat)vp.x / ftex_w, (GLfloat)vp.y / ftex_h, (GLfloat)vp.w / ftex_w, (GLfloat)vp.h / ftex_h };


	glUniform1fv(prog->uniforms[0], 1, &radius);
	glUniform1fv(prog->uniforms[1], 1, &height);
	glUniform3f(prog->uniforms[2],color.r,color.g,color.b);
	glow_make_draw(&vp, &dst_rb->clp, 1);

/*	char* pixels = caml_stat_alloc(4 * (GLuint)tex_w * (GLuint)tex_h);
	char* fname = malloc(255);
	static int save_tex_cnt = 0;
	sprintf(fname, "/tmp/pizda%04d.png", save_tex_cnt++);
	glReadPixels(0,0,tex_w,tex_h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	save_png_image(caml_copy_string(fname),pixels,tex_w,tex_h);*/

	glEnable(GL_BLEND);
	setNotPMAGLBlend ();
	glBindFramebuffer(GL_FRAMEBUFFER, dst_rb->fbid);
	glBindTexture(GL_TEXTURE_2D, txrs[tw_indx][th_indx]);
	prog = shadow_horizontal_blur_prog();

	glUniform1fv(prog->uniforms[0], 1, &radius);
	glUniform1fv(prog->uniforms[1], 1, &width);
	glUniform3f(prog->uniforms[2],color.r,color.g,color.b);
	vp = (viewport){ dst_rb->vp.x + sx, dst_rb->vp.y + sy, dst_rb->vp.w, dst_rb->vp.h };
	glow_make_draw(&vp, &clp, 0);

/*	pixels = caml_stat_alloc(4 * (GLuint)dst_rb->realWidth * (GLuint)dst_rb->realHeight);
	fname = malloc(255);
	sprintf(fname, "/tmp/pizda%04d.png", save_tex_cnt++);
	glReadPixels(0,0,dst_rb->realWidth,dst_rb->realHeight,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	save_png_image(caml_copy_string(fname),pixels,dst_rb->realWidth,dst_rb->realHeight);*/

	checkGLErrors("make draw");

	glBindTexture(GL_TEXTURE_2D,0);
	glUseProgram(0);
	currentShaderProgram = 0;
	set_framebuffer_state(&fstate);
	checkGLErrors("end of shadow");



//	Int_val(glow) // ocaml-int to C-int
//	Val_int(glow) // C-int to ocaml
/*
	texture: * orb has this type
 	typedef struct {
		GLuint fbid;
		GLuint tid;
		double width;
		double height;
		GLuint realWidth;
		GLuint realHeight;
		viewport vp;
		clipping clp;
	} renderbuffer_t;
	typedef struct {
		GLuint prg;
		GLint uniforms[4];
	} prg_t
*/
/*	lgResetBoundTextures();
	int rad = Int_val(Field(shadow,0));
	int colors = Int_val(Field(shadow,1));
	double redC   = (double) ((colors & 0xff0000) / 0x010000);
	double greenC = (double) ((colors & 0x00ff00) / 0x000100);
	double blueC  = (double) (colors & 0x0000ff);
	double vecX = Double_val(Field(shadow,2));
	double vecY = Double_val(Field(shadow,3));
//	printf("prg: %d %lf %lf\n", rad, vecX, vecY);
//	fflush(stdout);
	if (rad < 1)
		return; 
	// пикча
	renderbuffer_t *pic = (renderbuffer_t*)orb;
	currentShaderProgram = 0;

	// грузим шейдеры
	char *attribs[2] = {"a_position","a_texCoord"};
	GLuint prgH = create_program(simple_vertex_shader(),horizontal_blur_fsh(),2,attribs);
	glUseProgram(prgH);
	// инициализация
	glUniform1i(glGetUniformLocation(prgH,"u_texture"), 0);
	glUniform1f(glGetUniformLocation(prgH,"width"),(GLfloat)pic -> width);
	glUniform1i(glGetUniformLocation(prgH,"winRad"),(GLint)rad);
	glUniform1f(glGetUniformLocation(prgH,"ml"),(GLfloat)(1.0 / (rad * 2)));
	glUniform1f(glGetUniformLocation(prgH,"vecSh"),(GLfloat) vecX);

	GLuint prgV = create_program(simple_vertex_shader(),vertical_blur_fsh(),2,attribs);
	glUseProgram(prgV);
	glUniform1i(glGetUniformLocation(prgV,"u_texture"), 0);
	glUniform1f(glGetUniformLocation(prgV,"width"),(GLfloat)pic -> width);
	glUniform1i(glGetUniformLocation(prgV,"winRad"),(GLint)rad);
	glUniform1f(glGetUniformLocation(prgV,"ml"),(GLfloat)(1.0 / (rad * 2)));
	glUniform1f(glGetUniformLocation(prgV,"vecSh"),(GLfloat) vecY);
	glUniform1f(glGetUniformLocation(prgV,"redFL"), (GLfloat) redC);
	glUniform1f(glGetUniformLocation(prgV,"greenFL"), (GLfloat) greenC);
	glUniform1f(glGetUniformLocation(prgV,"blueFL"), (GLfloat) blueC);

	renderbuffer_t buf;
	renderbuffer_t *hBuffer = &buf;

	// create_renderbuffer(GLuint tid, int x, int y, double width, double height, int realW, int realH, renderbuffer_t *r, int dedicated);
	// create_renderbuffer(pic -> width, pic -> height, hBuffer, GL_LINEAR);

	int rectw = rb->realWidth;
	int recth = rb->realHeight;
	viewport rbvp = { rb->vp.x - (rectw - rb->vp.w) / 2, rb->vp.y - (recth - rb->vp.h) / 2, rectw, recth };

	double texw = rb->vp.w / rb->clp.width;
	double texh = rb->vp.h / rb->clp.height;
	clipping rbclp = { (GLfloat)rbvp.x / texw, (GLfloat)rbvp.y / texh, (GLfloat)rbvp.w  / texw, (GLfloat)rbvp.h  / texh };
	
	glUseProgram(prgH);

	glBindTexture(GL_TEXTURE_2D, pic -> tid);
/*	glEnable(GL_TEXTURE_2D);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pic -> realWidth, pic -> realHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glBindFramebuffer(GL_FRAMEBUFFER, hBuffer -> fbid);
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, hBuffer -> tid, 0);
	drawRenderbuffer(hBuffer,pic,1);

	glUseProgram(prgV);

	glBindTexture(GL_TEXTURE_2D, hBuffer -> tid);
	glEnable(GL_TEXTURE_2D);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, hBuffer -> realWidth, hBuffer -> realHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glBindFramebuffer(GL_FRAMEBUFFER, pic -> fbid);
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pic -> tid,0);
	drawRenderbuffer(pic,hBuffer,1);

	delete_renderbuffer(hBuffer);*/
}

value ml_glow_make(value orb, value glow) {
	int gsize = Int_val(Field(glow,0));
	if (gsize == 0) return Val_unit;
	renderbuffer_t *rb = (renderbuffer_t *)orb;

	int rectw = rb->realWidth;
	int recth = rb->realHeight;
	viewport rbvp = { rb->vp.x - (rectw - rb->vp.w) / 2, rb->vp.y - (recth - rb->vp.h) / 2, rectw, recth };

	double texw = rb->vp.w / rb->clp.width;
	double texh = rb->vp.h / rb->clp.height;
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

	/*
	if (bfrs == NULL) // можно пооптимальней это сделать
	{
		bfrs = caml_stat_alloc(maxFB * sizeof(GLuint));
		glGenFramebuffers(maxFB, bfrs);
	}
	*/
	INIT_BUFFERS;

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

	glBindFramebuffer(GL_FRAMEBUFFER, rb->fbid);
	_clear_renderbuffer(rb, (color3F) { 0., 0., 0.}, 0.);
	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTex);

	glEnable(GL_BLEND);
	setNotPMAGLBlend (); // WARNING - ensure what separate blend enabled
	const prg_t *fglowPrg = final_glow_program();
	glUniform1f(fglowPrg->uniforms[0],Double_val(Field(glow,2)));
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
	PRINT_DEBUG("ml_filter_cmatrix_extract call");

	CAMLparam1(vfilter);
	CAMLlocal1(retval);

	filter* f = FILTER(vfilter);
	GLfloat* data = (GLfloat*)f->data;
	retval = caml_alloc(20, Double_array_tag);
	int i;
	for (i = 0; i < 20; i++) {
		PRINT_DEBUG("%f", *(data + i));
		Store_double_field(retval, i, *(data + i));
	}

	PRINT_DEBUG("ml_filter_cmatrix_extract return");

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
	PRINT_DEBUG("strokeColorMatrixFilter");

	strokecolormatrix_t* d = (strokecolormatrix_t*)data;

	glUniform4fv(sp->uniforms[1], 1, d->color);
	glUniform1fv(sp->uniforms[2], 20,d->matrix);

	PRINT_DEBUG("strokeColorMatrixFilter done");
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
