#include <math.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <kazmath/GL/matrix.h>

#include "render_stub.h"

extern GLuint currentShaderProgram;

/*
static GLuint getFbTexSize() {
    static GLint size = 0;
    if (!size) {
#ifdef PC
		size = 512;
#else
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, &size);
		size = size / 4;
#endif
    }
    return size;
}

value ml_renderbuffer_tex_size() {
	return Val_int(getFbTexSize());
}
*/


/*
static GLuint currentFramebuffer = 0;

void my_glBindFramebuffer(GLuint newfbid) {
	if (currentFramebuffer != newfbid) {
		glBindFramebuffer(newfbid);
		currentFramebuffer = newfbid;
	};
}
*/

struct fb = 
{
	GLuint fbid;
	viewport viewport;
	fb *prev;
};

static struct fb *fb_state = NULL;

void fb_state_push(GLuint fbid, viewport *vp, int dogl) {
	struct fb *cfb = (struct fb*)malloc(sizeof(struct fb));
	cfb->fbid = fbid;
	cfb->viewport = *vp;
	cfb->prev = current_fb;
	fb_state = cfb;
	if (dogl) {
		glBindFramebuffer(GL_FRAMEBUFFER, fbid);
		glViewport(vp->x,vp->y,vp->w,vp->h);
	};
}

GLuint fb_state_restore(int vp) {
	glBindFramebuffer(GL_FRAMEBUFFER,fb_state->fbid);
	if (vp) glViewport(fb_state->viewport.x, fb_state->viewport.y, fb_state->viewport.w, fb_state->viewport.h);
}

void fb_state_pop() {
	struct fb *pfb = fb_state->prev;
	free(fb_state);
	fb_state = pfb;
	if (pfb->prev) fb_state_restore(1);
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

value ml_render_texture_id_delete(value textureID) {
	GLuint tid = TEXTURE_ID(textureID);
	if (tid) {
		PRINT_DEBUG("ml_render_texture_id_delete");
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
	return Val_unit;
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


static void inline renderbuffer_activate(renderbuffer_t *rb) {
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

static void inline renderbuffer_deactivate() {
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLPopMatrix();
	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLPopMatrix();
	disableSeparateBlend();// FIXME: incorrect in case deep rendering!!!!
}


static void _clear_renderbuffer(color3F clr, GLfloat alpha) {
	glDisable(GL_BLEND);
	const prg_t* clear_progr = clear_quad_progr();
	lgGLEnableVertexAttribs(lgVertexAttribFlag_Position);
	static GLfloat vertices[8] = { -1., -1., 1., -1., -1., 1., 1., 1. };
	glUniform4f(clear_progr->uniforms[0], clr.r, clr.g, clr.b, alpha);
 	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

/*
void clear_renderbuffer(renderbuffer_t* rb, value mlclear) {
	viewport* vp = &rb->vp;
	glViewport(vp->x - (rb->realWidth - vp->w) / 2, vp->y - (rb->realHeight - vp->h) / 2, rb->realWidth, rb->realHeight);
	int c = Int_val(Field(mlclear,0));
	color3F clr = COLOR3F_FROM_INT(c);
	GLfloat alpha = Double_val(Field(mlclear,1));
	_clear_renderbuffer(rb, clr, alpha);
	glUseProgram(0);
	currentShaderProgram = 0;
	glEnable(GL_BLEND);
	glViewport(vp->x, vp->y, vp->w, vp->h);
}
*/

value rendertexture_create(value mldedicated, value clear,value ml_width,value ml_height,value ml_func) {
	CAMLlocal2(vtid,renderInfo);
	uint16_t width = ceil(Double_val(ml_width));
  uint16_t height = ceil(Double_val(ml_height));
	GLuint fb_tex_size = getFbTexSize();
	int dedicated = 0;
	GLuint filter = GL_LINEAR;
	if (Is_long(mldedicated)) {
		if (Int_val(mldedicated) != 0) caml_failwith("Incorrect dedicated value");
	} else 
		if (Tag_val(mldedicated) == 0) {// Dedicated
			dedicated = 1;
			switch (Int_val(Field(mldedicated,0))) {
				case 0: filter = GL_NEAREST; break;
				case 1: filter = GL_LINEAR; break;
				default: break;
			}
		}
	}
	dedicated ||=  (width > (fb_tex_size / 2)) || (height > (fb_tex_size / 2));
	renderbuffer_t rb;
	lgResetBoundTextures();
	value ca = Field(mlclear,0);
	int c = Int_val(Field(ca,0));
	color3F clr = COLOR3F_FROM_INT(c);
	GLfloat alpha = Double_val(Field(ca,1));
	if (dedicated) {
      GLuint rectw = nextPOT(width);
      GLuint recth = nextPOT(height);
      GLuint offsetx = (rectw - width) / 2;
      GLuint offsety = (recth - height) / 2;

			r.tid = get_texture_id();
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, rectw, recth, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
			checkGLErrors("create render texture %d [%d:%d]", tid, rectw, recth);
			int size = (int)(rectw * recth * 4);
			r.fbid = get_framebuffer();
			r.vp = (viewport){ offsetx, offsety, rectw, recth };
			r.clp = (clipping){ (double)offsetx / (double)rectw, (double)offsety / (double)recth, width / (double)rectw, height / (double)recth };

			fb_state_push(r.fbid,&r.vp,1);

			glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rb.tid, 0);
			if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) caml_failwith("Framebuffer status error");


			renderbuffer_activate(&rb);

			glClearColor(clr.r, clr.g, clr.b, alpha);
			glClear(GL_COLOR_BUFFER_BIT);

			caml_callback(mlfun,(value)&rb);

			glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
			renderbuffer_deactivate();
			fb_state_pop();
			back_framebuffer(rb.fbid);
	} else {
		shared_texture_get_rect(rectw,recth,&rb);// FIXME: check result
		glBindFramebuffer(rb.fbid);
		_clear_renderbuffer(clr,alpha);
		fb_state_push(rb.fbid,&rb.vp,0);
		glViewport(rb.vp.x,rb.vp.y,rb.vp.width,rb.vp.height);
		renderbuffer_activate(&rb);// work with matrix
		caml_callback(mlfun,(value)&rb);
		renderbuffer_deactivate();
		fb_state_pop();
	};

	Store_rendertextureID(vtid, rb.tid, size);	
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

	Store_field(renderInfo,0, vtid);
	Store_field(renderInfo,1, caml_copy_double(rb.width));
	Store_field(renderInfo,2, caml_copy_double(rb.height));
	Store_field(renderInfo,3,clip);
	Store_field(renderInfo,4,kind);
	//Store_field(renderInfo,5,Val_int(rb.vp.x));
	//Store_field(renderInfo,6,Val_int(rb.vp.y));
	checkGLErrors("finish render to texture");
	CAMLreturn(renderInfo);
}


value rendertexture_draw(value renderInfo, value new_params, value mlclear, value mlfun) {
	// хуй с ним, будем высчитывать фсю хуйню
}
