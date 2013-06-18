#include <stdio.h>
#include <math.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <kazmath/GL/matrix.h>
#include "render_stub.h"
#include "renderbuffer_stub.h"

#include "texture_save.h"
#include "inline_shaders.h"

extern GLuint currentShaderProgram;

static int fbs_cnt = 0;
static GLuint *fbfs = NULL;

static GLuint getFbTexSize() {
    static GLint size = 0;
    if (!size) {
    	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &size);
    	size = size / 4;
    }

    return size;
}

value ml_renderbuffer_tex_size() {
	return Val_int(getFbTexSize());
}

static GLuint inline get_framebuffer() {
	GLuint fbid = 0;
	int i = 0;
	while ((i < fbs_cnt) && (fbfs[i] == 0)) {i++;};
	if (i < fbs_cnt) {
		fbid = fbfs[i];
		fbfs[i] = 0;
	} else glGenFramebuffers(1,&fbid);
	PRINT_DEBUG("get framebuffer: %d",fbid);
	return fbid;
}

static void inline back_framebuffer(GLuint fbid) {
	int i = 0;
	while (i < fbs_cnt && fbfs[i] != 0) {i++;};
	if (i < fbs_cnt) fbfs[i] = fbid;
	else {
		fbfs = realloc(fbfs,sizeof(GLuint)*(fbs_cnt + 1));
		fbfs[fbs_cnt] = fbid;
		++fbs_cnt;
	}
	PRINT_DEBUG("back framebuffer: %d",fbid);
}

static int tx_cnt = 0;
static GLuint *txs = NULL;


static GLuint inline get_texture_id() {
	GLuint tid = 0;
	int i = 0;
	while ((i < tx_cnt) && (txs[i] == 0)) {i++;};
	if (i < tx_cnt) {
		tid = txs[i];
		txs[i] = 0;
		glBindTexture(GL_TEXTURE_2D, tid);
	} else {
		glGenTextures(1,&tid);
		glBindTexture(GL_TEXTURE_2D, tid);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	};
	PRINT_DEBUG("get texture: %d",tid);
	return tid;
}

static void inline back_texture_id(GLuint tid) {
	int i = 0;
	while (i < tx_cnt && txs[i] != 0) {i++;};
	if (i < tx_cnt) {
		txs[i] = tid;
	} else {
		txs = realloc(txs,sizeof(GLuint)*(tx_cnt + 1));
		txs[tx_cnt] = tid;
		++tx_cnt;
	}
	PRINT_DEBUG("back texture: %d",tid);
}

static unsigned int total_tex_mem = 0;
static unsigned int total_tex_count = 0;
extern uintnat caml_dependent_size;

#ifdef TEXTURE_LOAD
#define LOGMEM(op,tid,size) DEBUGMSG("RENDER TEXTURE MEMORY [%s] <%d:%d> -> %d  %u:%u",op,tid,size,total_tex_count,total_tex_mem,caml_dependent_size);
#else
#define LOGMEM(op,tid,size)
#endif

void ml_render_texture_id_delete(value textureID) {
	GLuint tid = TEXTURE_ID(textureID);
	if (tid) {
		back_texture_id(tid);
		resetTextureIfBounded(tid);
		checkGLErrors("delete texture");
		struct tex *t = TEX(textureID);
		t->tid = 0;
		total_tex_mem -= t->mem;
		--total_tex_count;
		LOGMEM("delete",tid,t->mem);
		caml_free_dependent_memory(t->mem);
	};
}

static void textureID_finalize(value textureID) {
	GLuint tid = TEXTURE_ID(textureID);
	if (tid) {
		PRINT_DEBUG("finalize render texture");
		back_texture_id(tid);
		resetTextureIfBounded(tid);
		checkGLErrors("finalize texture");
		struct tex *t = TEX(textureID);
		total_tex_mem -= t->mem;
		--total_tex_count;
		caml_free_dependent_memory(t->mem);
		LOGMEM("finalize",tid,t->mem);
	};
}

static int textureID_compare(value texid1,value texid2) {
	GLuint t1 = TEXTURE_ID(texid1);
	GLuint t2 = TEXTURE_ID(texid2);
	if (t1 == t2) return 0;
	else {
		if (t1 < t2) return -1;
		return 1;
	}
}

struct custom_operations rendertextureID_ops = {
  "pointer to render texture id",
  textureID_finalize,
  textureID_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

#define MAX_RENDER_TEXTURES 100


value caml_gc_major(value v);

#define Store_rendertextureID(mltex,texID,dataLen) \
	if (++total_tex_count >= MAX_RENDER_TEXTURES) { \
		PRINT_DEBUG("gc call"); \
		caml_gc_major(0); \
	} \
	caml_alloc_dependent_memory(dataLen); \
	mltex = caml_alloc_custom(&rendertextureID_ops, sizeof(struct tex), dataLen, MAX_GC_MEM); \
	{struct tex *_tex = TEX(mltex); _tex->tid = texID; _tex->mem = dataLen;  total_tex_mem += dataLen;LOGMEM("new",texID,dataLen)}

void get_framebuffer_state(framebuffer_state *s) {
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &s->framebuffer);
	glGetIntegerv(GL_VIEWPORT,s->viewport);
	checkGLErrors("get framebuffer state");
}

static void inline renderbuffer_activate(renderbuffer_t *rb) {
	glViewport(rb->vp.x,rb->vp.y,rb->vp.w,rb->vp.h);
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLPushMatrix();
	kmGLLoadIdentity();
	kmMat4 orthoMatrix;
	kmMat4OrthographicProjection(&orthoMatrix, 0, (GLfloat)rb->vp.w, 0, (GLfloat)rb->vp.h, -1024, 1024 );
	kmGLMultMatrix( &orthoMatrix );
	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLPushMatrix();
	kmGLLoadIdentity();
	enableSeparateBlend();
}


void set_framebuffer_state(framebuffer_state *s) {
	glBindFramebuffer(GL_FRAMEBUFFER,s->framebuffer);
	glViewport(s->viewport[0], s->viewport[1], s->viewport[2], s->viewport[3]);
}

static void inline renderbuffer_deactivate() {
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLPopMatrix();
	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLPopMatrix();
	disableSeparateBlend();
}


#define GL_ERROR  																						\
GLenum gl_err = glGetError();																			\
char* gl_err_str;																						\
																										\
switch (gl_err) {																						\
	case GL_NO_ERROR: gl_err_str = "GL_NO_ERROR"; break;												\
	case GL_INVALID_ENUM: gl_err_str = "GL_INVALID_ENUM"; break;										\
	case GL_INVALID_VALUE: gl_err_str = "GL_INVALID_VALUE"; break;										\
	case GL_INVALID_OPERATION: gl_err_str = "GL_INVALID_OPERATION"; break;								\
	case GL_INVALID_FRAMEBUFFER_OPERATION: gl_err_str = "GL_INVALID_FRAMEBUFFER_OPERATION"; break;		\
	case GL_OUT_OF_MEMORY: gl_err_str = "GL_OUT_OF_MEMORY"; break;										\
	default: gl_err_str = "unknown gl error";															\
}																										\
																										\
PRINT_DEBUG("GL ERROR: %s", gl_err_str);																\

static int FRAMEBUFFER_BIND_COUNTER = 0;

void clear_renderbuffer(renderbuffer_t* rb, value mlclear) {
	PRINT_DEBUG("clear_renderbuffer call");

	if (Is_block(mlclear)) {
		PRINT_DEBUG("clear_renderbuffer mlclear != Val_none");
		value ca = Field(mlclear,0);
		int c = Int_val(Field(ca,0));
		color3F clr = COLOR3F_FROM_INT(c);
		GLfloat alpha = Double_val(Field(ca,1));

		viewport* vp = &rb->vp;
		glViewport(vp->x, vp->y, vp->w, vp->h);
		glDisable(GL_BLEND);
		const prg_t* clear_progr = clear_quad_progr();
		lgGLEnableVertexAttribs(lgVertexAttribFlag_Position);
		static GLfloat vertices[8] = { -1., -1., 1., -1., -1., 1., 1., 1. };
		glUniform4f(clear_progr->uniforms[0], clr.r, clr.g, clr.b, alpha);
	 	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glUseProgram(0);
		currentShaderProgram = 0;
		glEnable(GL_BLEND);
	}
}

int create_renderbuffer(GLuint tid, int x, int y, double width, double height, int realW, int realH, renderbuffer_t *r/*, GLenum filter*/) {
    double w = ceil(width);
    double h = ceil(height);
	// GLuint gl_w = (GLuint)w;
	// GLuint gl_h = (GLuint)h;

    GLuint fbid = get_framebuffer();
    glBindFramebuffer(GL_FRAMEBUFFER, fbid);
	checkGLErrors("bind framebuffer %d",fbid);

	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tid, 0);    
	FRAMEBUFFER_BIND_COUNTER++;
	PRINT_DEBUG("tid %d", tid);
	checkGLErrors("framebuffertexture2d %d -> %d",fbid, tid);


	// double texSize = (double)getFbTexSize();


    r->fbid = fbid;
    r->tid = tid;

    // PRINT_DEBUG("create_renderbuffer %d %d %d %d", x, y, gl_w, gl_h);
	r->vp = (viewport){ (GLuint)x, (GLuint)y, (GLuint)w, (GLuint)h };
	r->clp = (clipping){ (double)r->vp.x / (double)realW, (double)r->vp.y / (double)realH, w / (double)realW, h / (double)realH };
    r->width = w;
    r->height = h;
	r->realWidth = realW;
	r->realHeight = realH;

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return 1;

  	return 0;
}


/*int clone_renderbuffer(renderbuffer_t *sr, renderbuffer_t *dr, GLenum filter) {
	GLuint rtid;
 	glGenTextures(1, &rtid);
  	glBindTexture(GL_TEXTURE_2D, rtid);
  	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
  	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
  	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, sr->realWidth, sr->realHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	//checkGLErrors("create renderbuffer texture %d [%d:%d]",rtid,legalWidth,legalHeight);
  	glBindTexture(GL_TEXTURE_2D,0);
  	GLuint fbid;
  	glGenFramebuffers(1, &fbid);
  	glBindFramebuffer(GL_FRAMEBUFFER, fbid);
  	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rtid,0);
	FRAMEBUFFER_BIND_COUNTER++;
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		PRINT_DEBUG("clone_renderbuffer");
		GL_ERROR;
		return 1;
	}
	dr->fbid = fbid;
	dr->tid = rtid;
	dr->vp = sr->vp;
	dr->clp = sr->clp;
	dr->width = sr->width;
	dr->height = sr->height;
	dr->realWidth = sr->realWidth;
	dr->realHeight = sr->realHeight;
	return 0;
}
*/
void delete_renderbuffer(renderbuffer_t *rb) {
	glDeleteTextures(1,&rb->tid);
	back_framebuffer(rb->fbid);
}

static int pizdalala = 0;

value ml_renderbuffer_draw(value dedicated, value filter, value mlclear, value tid, value mlx, value mly, value mlwidth, value mlheight, value mlfun) {
	PRINT_DEBUG("ml_renderbuffer_draw CALL");

	CAMLparam5(filter, mlclear, tid, mlx, mly);
	CAMLxparam3(mlwidth, mlheight, mlfun);
	CAMLlocal4(renderInfo, clp, clip, kind);


/*	GLenum fltr;
	switch (Int_val(filter)) {
		case 0: 
			fltr = GL_NEAREST;
			break;
		case 1:
			fltr = GL_LINEAR;
			break;
		default: break;
	};*/

	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	renderbuffer_t rb;

	double w = Double_val(mlwidth), h = Double_val(mlheight);
	int realW, realH;

	if (dedicated == Val_true) {
		realW = nextPOT(ceil(w));
		realH = nextPOT(ceil(h));
	} else {
		realW = realH = getFbTexSize();
	}

	if (create_renderbuffer(TEXTURE_ID(tid), Int_val(mlx), Int_val(mly), w, h, realW, realH, &rb)) {
		char emsg[255];
		sprintf(emsg,"renderbuffer_draw. create framebuffer '%d', texture: '%d' [%d:%d], status: %X, counter: %d",rb.fbid,rb.tid,rb.realWidth,rb.realHeight,glCheckFramebufferStatus(GL_FRAMEBUFFER),FRAMEBUFFER_BIND_COUNTER);
		set_framebuffer_state(&fstate);
		caml_failwith(emsg);
	};

	lgResetBoundTextures();
	checkGLErrors("renderbuffer create");
	renderbuffer_activate(&rb);

	clear_renderbuffer(&rb, mlclear);
	caml_callback(mlfun,(value)&rb);

 	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
	renderbuffer_deactivate();

	set_framebuffer_state(&fstate);
	back_framebuffer(rb.fbid);

	clp = caml_alloc(4 * Double_wosize,Double_array_tag);
	Store_double_field(clp,0,rb.clp.x);
	Store_double_field(clp,1,rb.clp.y);
	Store_double_field(clp,2,rb.clp.width);
	Store_double_field(clp,3,rb.clp.height);
	clip = caml_alloc_tuple(1);
	Store_field(clip,0,clp);

	kind = caml_alloc_tuple(1);
	Store_field(kind,0,Val_true);

	renderInfo = caml_alloc_tuple(7);

	Store_field(renderInfo,0, tid);
	Store_field(renderInfo,1, caml_copy_double(rb.width));
	Store_field(renderInfo,2, caml_copy_double(rb.height));
	Store_field(renderInfo,3,clip);
	Store_field(renderInfo,4,kind);
	Store_field(renderInfo,5,Val_int(rb.vp.x));
	Store_field(renderInfo,6,Val_int(rb.vp.y));
	checkGLErrors("finish render to texture");

	CAMLreturn(renderInfo);
}

value ml_renderbuffer_draw_byte(value * argv, int n) {
	return (ml_renderbuffer_draw(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],argv[8]));
}

void ml_renderbuffer_draw_to_texture(value mlclear, value new_params, value new_tid, value renderInfo, value mlfun) {
	PRINT_DEBUG("ml_renderbuffer_draw_to_texture");
	CAMLparam5(mlclear, new_params, new_tid, renderInfo, mlfun);
	CAMLlocal2(clp, clip);

	int x;
	int y;
	double w;
	double h;
	GLuint tid;
	int resized = 0;

	if (Is_block(new_params)) {
		value _new_params = Field(new_params, 0);
		x = Int_val(Field(_new_params, 0));
		y = Int_val(Field(_new_params, 1));
		w = Double_val(Field(_new_params, 2));
		h = Double_val(Field(_new_params, 3));
		resized = 1;
	} else {
		x = Int_val(Field(renderInfo, 5));
		y = Int_val(Field(renderInfo, 6));
		w = Double_val(Field(renderInfo,1));
		h = Double_val(Field(renderInfo,2));
	}

	if (Is_block(new_tid)) {
		tid = TEXTURE_ID(Field(new_tid, 0));
		Store_field(renderInfo, 0, Field(new_tid, 0));		
	} else {
		tid = TEXTURE_ID(Field(renderInfo, 0));
	}

	framebuffer_state fstate;
	get_framebuffer_state(&fstate);

	renderbuffer_t rb;

	if (create_renderbuffer(tid, x, y, w, h, getFbTexSize(), getFbTexSize(), &rb)) {
		char emsg[255];
		sprintf(emsg,"renderbuffer_draw. create framebuffer '%d', texture: '%d' [%d:%d], status: %X, counter: %d",rb.fbid,rb.tid,rb.realWidth,rb.realHeight,glCheckFramebufferStatus(GL_FRAMEBUFFER),FRAMEBUFFER_BIND_COUNTER);
		set_framebuffer_state(&fstate);
		caml_failwith(emsg);
	};

	if (resized) {
		Store_field(renderInfo,1, caml_copy_double(w));
		Store_field(renderInfo,2, caml_copy_double(h));
		Store_field(renderInfo,5, Val_int(x));
		Store_field(renderInfo,6, Val_int(y));

		clp = caml_alloc(4 * Double_wosize,Double_array_tag);
		Store_double_field(clp,0,rb.clp.x);
		Store_double_field(clp,1,rb.clp.y);
		Store_double_field(clp,2,rb.clp.width);
		Store_double_field(clp,3,rb.clp.height);
		clip = caml_alloc_small(1,0);
		Store_field(clip,0,clp);
		Store_field(renderInfo,3,clip);
	}

	lgResetBoundTextures();
	checkGLErrors("renderbuffer create");
	renderbuffer_activate(&rb);

	clear_renderbuffer(&rb, mlclear);
	caml_callback(mlfun,(value)&rb);

/*	//------------
	// glBindFramebuffer(GL_FRAMEBUFFER, rb->fbid);
	char* pixels = caml_stat_alloc(4 * (GLuint)512 * (GLuint)512);
	char* fname = malloc(255);
	sprintf(fname, "/sdcard/xyu_%d_%03d.png", TEXTURE_ID(tid), pizdalala++);
	glReadPixels(0,0,512,512,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	save_png_image(caml_copy_string(fname),pixels,512,512);	
	//------------*/

	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, 0, 0);
	set_framebuffer_state(&fstate);
	renderbuffer_deactivate();
	back_framebuffer(rb.fbid);

	checkGLErrors("finish render to texture");

	CAMLreturn0;
}

value ml_renderbuffer_draw_to_dedicated_texture(value mlclear, value owidth, value oheight, value renderInfo, value mlfun) {
	CAMLparam4(renderInfo,owidth,oheight,mlfun);
	CAMLlocal1(clp);

	double cwidth = Double_val(Field(renderInfo,1));
	double cheight = Double_val(Field(renderInfo,2));


	int resized = 0;
	double width = cwidth;
	//fprintf(stderr,"try resize %d:%d from [%f:%f] to [%f:%f]\n",rb->fbid,rb->tid,rb->width,rb->height,width,height);
	if (owidth != Val_none) {
		width = Double_val(Field(owidth,0));
		resized = (width != cwidth);
	};
	double height = cheight;
	if (oheight != Val_none) {
		height = Double_val(Field(oheight,0));
		resized |= (height != cheight);
	};
	PRINT_DEBUG("draw to texture: [%f:%f] -> [%f:%f]",cwidth,cheight,width,height);

	GLuint legalWidth = nextPOT(ceil(width));
	GLuint legalHeight = nextPOT(ceil(height));
	TEXTURE_SIZE_FIX(legalWidth,legalHeight);
	renderbuffer_t rb;
	rb.tid = TEXTURE_ID(Field(renderInfo,0));
  rb.width = width;
  rb.height = height;
	rb.realWidth = legalWidth;
	rb.realHeight = legalHeight;
	rb.vp = (viewport){(GLuint)((legalWidth - width)/2),(GLuint)((legalHeight - height)/2),(GLuint)width,(GLuint)height};
	if (resized) {
		Store_field(renderInfo,1,caml_copy_double(width));
		Store_field(renderInfo,2,caml_copy_double(height));
		value clip;
		if (legalWidth == width && legalHeight == height) {
			rb.clp = (clipping){0.,0.,1.,1.};
			clip = Val_unit;
		} else {
			rb.clp = (clipping) {
				(double)rb.vp.x / legalWidth,
				(double)rb.vp.y / legalHeight,
				(width / legalWidth),
				(height / legalHeight)
			};
			clp = caml_alloc(4 * Double_wosize,Double_array_tag);
			Store_double_field(clp,0,rb.clp.x);
			Store_double_field(clp,1,rb.clp.y);
			Store_double_field(clp,2,rb.clp.width);
			Store_double_field(clp,3,rb.clp.height);
			clip = caml_alloc_tuple(1);
			Store_field(clip,0,clp);
		};
		PRINT_DEBUG("update texture params: %f:%f -> [%f:%f:%f:%f]",width,height,rb.clp.x,rb.clp.y,rb.clp.width,rb.clp.height);
		Store_field(renderInfo,3,clip);
		if (legalWidth != nextPOT(ceil(cwidth)) || legalHeight != nextPOT(ceil(cheight))) {

			lgGLBindTexture(rb.tid,1);
			glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,legalWidth,legalHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
			//rb->realWidth = legalWidth;
			//rb->realHeight = legalHeight;

			/*TEX(Field(renderInfo,0))->tid = 0;
			total_tex_mem -= TEX(Field(renderInfo,0))->mem;
			caml_free_dependent_memory(TEX(Field(renderInfo,0))->mem);*/
			//ml_texture_id_delete(Field(renderInfo,0));
			int s = legalWidth*legalHeight*4;
			update_texture_id_size(Field(renderInfo,0),s);
			//value mlTextureID = texture_id_alloc(rb.tid,s);
			//Store_textureID(mlTextureID,rb->tid,"renderbuffer resized",s);
			//Store_field(renderInfo,0,mlTextureID); // ??
			checkGLErrors("renderbuffer resize");
		};
	} else {
		// Достать clp из ocaml 
		clp = Field(renderInfo,3);
		if (clp == Val_none)
      rb.clp = (clipping) {0.,0.,1.,1.};
    else {
			clp = Field(clp,0);
			rb.clp = (clipping) {Double_field(clp,0),Double_field(clp,1),Double_field(clp,2),Double_field(clp,3)};
		}
	};

	framebuffer_state fstate;
	get_framebuffer_state(&fstate);

	//Теперь делаем фрэймбуффер
  //glGenFramebuffers(1, &rb.fbid);
	rb.fbid = get_framebuffer();
  glBindFramebuffer(GL_FRAMEBUFFER, rb.fbid);
	PRINT_DEBUG("FRAMEBUFFER BINDED");
	checkGLErrors("draw to texture bind framebuffer");
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rb.tid,0);
	FRAMEBUFFER_BIND_COUNTER++;
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
  		PRINT_DEBUG("ml_renderbuffer_draw_to_texture");
  		GL_ERROR;

		char emsg[255];
		sprintf(emsg,"draw to texture framebuffer '%d', texture: '%d' [%d:%d], status: %X, counter: %d",rb.fbid,rb.tid,legalWidth,legalHeight,glCheckFramebufferStatus(GL_FRAMEBUFFER),FRAMEBUFFER_BIND_COUNTER);
		set_framebuffer_state(&fstate);
    caml_failwith(emsg);
  };

	// clear 

	renderbuffer_activate(&rb);

	if (mlclear != Val_none) {
		value ca = Field(mlclear,0);
		int c = Int_val(Field(ca,0));
		color3F clr = COLOR3F_FROM_INT(c);
		GLfloat alpha = Double_val(Field(ca,1));
		glClearColor(clr.r,clr.g,clr.b,alpha);
		glClear(GL_COLOR_BUFFER_BIT);
	}

	caml_callback(mlfun,(value)&rb);

	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,0,0);// Detach the texture

	set_framebuffer_state(&fstate);
	renderbuffer_deactivate();
	//glDeleteFramebuffers(1,&rb.fbid);
	back_framebuffer(rb.fbid);

	checkGLErrors("finish render to texture");
	CAMLreturn(Val_bool(resized));
 }

value ml_renderbuffer_data(value renderInfo) {
	CAMLparam1(renderInfo);
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	double width = Double_val(Field(renderInfo,1));
	double height = Double_val(Field(renderInfo,2));
	GLuint legalWidth = nextPOT(ceil(width));
	GLuint legalHeight = nextPOT(ceil(height));
	GLuint fbid = get_framebuffer();
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
	GLuint tid = TEXTURE_ID(Field(renderInfo,0));
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,tid,0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
  		PRINT_DEBUG("ml_renderbuffer_data");
  		GL_ERROR;

		char emsg[255];
		sprintf(emsg,"save framebuffer '%d', texture: '%d' [%d:%d], status: %X, counter: %d",fbid,tid,legalWidth,legalHeight,glCheckFramebufferStatus(GL_FRAMEBUFFER),FRAMEBUFFER_BIND_COUNTER);
		set_framebuffer_state(&fstate);
    caml_failwith(emsg);
  };
	viewport vp = (viewport){
		(GLuint)((legalWidth - width)/2),
		(GLuint)((legalHeight - height)/2),
		(GLuint)width,(GLuint)height
	};
	char *pixels = caml_stat_alloc(4 * (GLuint)width * (GLuint)height);

	glReadPixels(vp.x,vp.y,vp.w,vp.h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);

	checkGLErrors("after read pixels");

	intnat dims[2];
	dims[0] = width;
	dims[1] = height;

	value vbuf = caml_ba_alloc(CAML_BA_MANAGED|CAML_BA_INT32, 2, pixels, dims);

	set_framebuffer_state(&fstate);

	CAMLreturn(vbuf);
}

value ml_renderbuffer_save(value renderInfo,value filename) {
	framebuffer_state fstate;
	get_framebuffer_state(&fstate);
	double width = Double_val(Field(renderInfo,1));
	double height = Double_val(Field(renderInfo,2));
	GLuint legalWidth = nextPOT(ceil(width));
	GLuint legalHeight = nextPOT(ceil(height));
	GLuint fbid = get_framebuffer();
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
	GLuint tid = TEXTURE_ID(Field(renderInfo,0));
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,tid,0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		char emsg[255];
		sprintf(emsg,"save framebuffer '%d', texture: '%d' [%d:%d], status: %X, counter: %d",fbid,tid,legalWidth,legalHeight,glCheckFramebufferStatus(GL_FRAMEBUFFER),FRAMEBUFFER_BIND_COUNTER);
		set_framebuffer_state(&fstate);
    caml_failwith(emsg);
  };
	viewport vp = (viewport){
		Int_val(Field(renderInfo, 5)), Int_val(Field(renderInfo, 6)),(GLuint)width,(GLuint)height
	};
	char *pixels = caml_stat_alloc(4 * (GLuint)width * (GLuint)height);
	PRINT_DEBUG("vp.x %d,vp.y %d,vp.w %d,vp.h %d", vp.x,vp.y,vp.w,vp.h);
	glReadPixels(vp.x,vp.y,vp.w,vp.h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
	checkGLErrors("after read pixels");
	int res = save_png_image(filename,pixels,vp.w,vp.h);
	set_framebuffer_state(&fstate);
	return Val_bool(res);
}

value ml_create_renderbuffer_tex(value v_size) {
	PRINT_DEBUG("ml_create_renderbuffer_tex call");

	CAMLparam0();
	CAMLlocal1(vtid);

	GLuint tid, texW, texH;

	if (Is_block(v_size)) {
		texW = nextPOT(Int_val(Field(Field(v_size, 0), 0)));
		texH = nextPOT(Int_val(Field(Field(v_size, 0), 1)));
	} else {
		texW = texH = getFbTexSize();
	}

	glGenTextures(1, &tid);
	glBindTexture(GL_TEXTURE_2D, tid);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texW, texH, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glBindTexture(GL_TEXTURE_2D,0);
	checkGLErrors("create render texture %d [%d:%d]", tid, texW, texH);

	int size = (int)(texW * texH * 4);
	Store_rendertextureID(vtid, tid, size);	
	
	CAMLreturn(vtid);
}
