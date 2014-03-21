#ifndef RENDERTEX_COMMON_H
#define RENDERTEX_COMMON_H

#include "light_common.h"
#include "texture_common.h"

#define RENDERBUF_OF_RENDERINF(renderbuf, renderinf, real_dim_fun) { \
	struct tex *t = TEX(Field(renderinf, 0)); \
	renderbuf.fbid = t->fbid; \
	renderbuf.tid = t->tid; \
	\
	renderbuf.width = Double_val(Field(renderinf, 1)); \
	renderbuf.height = Double_val(Field(renderinf, 2)); \
	renderbuf.realWidth = real_dim_fun(ceil(renderbuf.width)); \
	renderbuf.realHeight = real_dim_fun(ceil(renderbuf.height)); \
	\
	value vclipping = Field(renderinf, 4); \
	renderbuf.clp = Is_block(vclipping) ? (clipping){ Double_field(vclipping, 0), Double_field(vclipping, 1), Double_field(vclipping, 2), Double_field(vclipping, 3) } : (clipping){ 0., 0., 1., 1. }; \
	renderbuf.vp = (viewport) { Int_val(Field(renderinf, 5)), Int_val(Field(renderinf, 6)), renderbuf.width, renderbuf.height }; \
}

enum {
	FRAMEBUF_APPLY_SKIP = 0, //do not apply buffer nor viewport, just push record in stack
	FRAMEBUF_APPLY_BUF = 1, //bind framebuffer id only 
	FRAMEBUF_APPLY_VIEWPORT = 1 << 2, //set viewport only
	FRAMEBUF_APPLY_ALL = FRAMEBUF_APPLY_BUF | FRAMEBUF_APPLY_VIEWPORT //both framebuffer binding and viewport setting
};

typedef struct {
	GLfloat x;
	GLfloat y;
	GLfloat w;
	GLfloat h;
} clipping;

typedef struct {
	GLsizei x;
	GLsizei y;
	GLsizei w;
	GLsizei h;
} viewport;

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

void 	renderbuf_activate 		(renderbuffer_t *rb);
void 	renderbuf_deactivate	();
uint8_t renderbuf_save			(renderbuffer_t *rb, value path, uint8_t whole);
uint8_t renderbuf_save_current	(value path);

GLuint	tex_get_id				();
void	tex_return_id			(GLuint tid);

GLuint	framebuf_get_id			();
void	framebuf_return_id		(GLuint fbid);
void 	framebuf_push			(GLuint fbid, viewport *vp, int8_t apply);
void	framebuf_pop			();
void	framebuf_restore		(int8_t apply_viewport);

#endif