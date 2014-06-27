#include "common.h"
#include <kazmath/GL/matrix.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include "texture_save.h"

struct framebuf_state {
	GLuint fbid;
	viewport viewport;
	struct framebuf_state *prev;
};

typedef struct framebuf_state framebuf_state_t;

static framebuf_state_t *framebuf_stack = NULL;

#define APPLY_VIEWPORT(vp) { caml_callback2(*caml_named_value("setScissor"), caml_copy_double((double)vp->x), caml_copy_double((double)vp->y)); glViewport(vp->x, vp->y, vp->w, vp->h); }

void framebuf_push(GLuint fbid, viewport *vp, int8_t apply) {
	PRINT_DEBUG("+++framebuf_push id %d, vp (%d, %d, %d, %d), apply id %d, apply vp %d", fbid, vp->x, vp->y, vp->w, vp->h, apply & FRAMEBUF_APPLY_BUF, apply & FRAMEBUF_APPLY_VIEWPORT);

	if (framebuf_stack && framebuf_stack->fbid == fbid) apply &= FRAMEBUF_APPLY_BUF ^ FRAMEBUF_APPLY_BUF;

	framebuf_state_t *state = (framebuf_state_t*)malloc(sizeof(framebuf_state_t));
	state->fbid = fbid;
	state->viewport = *vp;
	state->prev = framebuf_stack;
	framebuf_stack = state;

	if (apply & FRAMEBUF_APPLY_BUF) glBindFramebuffer(GL_FRAMEBUFFER, fbid);
	if (apply & FRAMEBUF_APPLY_VIEWPORT) APPLY_VIEWPORT(vp);
}

void framebuf_restore(int8_t apply_viewport) {
	PRINT_DEBUG("???framebuf_restore %d %d %d %d",framebuf_stack->viewport.x, framebuf_stack->viewport.y, framebuf_stack->viewport.w, framebuf_stack->viewport.h);
	glBindFramebuffer(GL_FRAMEBUFFER, framebuf_stack->fbid);

	if (apply_viewport) {
		viewport *vp = &framebuf_stack->viewport;
		APPLY_VIEWPORT(vp);
	}
}

void framebuf_pop() {
	PRINT_DEBUG("---framebuf_pop");

	if (!framebuf_stack) return;

	framebuf_state_t *state = framebuf_stack->prev;
	free(framebuf_stack);
	framebuf_stack = state;

	if (framebuf_stack) framebuf_restore(1);
}

void inline renderbuf_activate(renderbuffer_t *rb) {
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

void inline renderbuf_deactivate() {
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLPopMatrix();
	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLPopMatrix();
	disableSeparateBlend();// FIXME: incorrect in case deep rendering!!!!
}

uint8_t renderbuf_save_current(value path) {
	GLfloat vp[4];
	glGetFloatv(GL_VIEWPORT, vp);

	PRINT_DEBUG("renderbuf_save_current %f %f %f %f", vp[0], vp[1], vp[2], vp[3]);

	char *pixels = caml_stat_alloc(4 * (GLuint)vp[2] * (GLuint)vp[3]);
	glReadPixels((GLint)vp[0], (GLint)vp[1], (GLsizei)vp[2], (GLsizei)vp[3], GL_RGBA, GL_UNSIGNED_BYTE, pixels);
	uint8_t retval = save_png_image(path, pixels, (unsigned int)vp[2], (unsigned int)vp[3]);

	return retval;	
} 

uint8_t renderbuf_save(renderbuffer_t *renderbuf, value path, uint8_t whole) {
	viewport vp = whole
		? (viewport){ 0., 0., (float)renderbuf->vp.w / renderbuf->clp.w, (float)renderbuf->vp.h / renderbuf->clp.h }
		: renderbuf->vp;

	framebuf_push(renderbuf->fbid, &vp, FRAMEBUF_APPLY_ALL);
	uint8_t retval = renderbuf_save_current(path);
	framebuf_pop();

	return retval;
}

static int framebuf_len = 0;
static GLuint *framebufs = NULL;

void framebuf_get_id(GLuint *fbid, GLuint *tid, GLuint w, GLuint h, GLuint filter) {
	int i = 0;
	while (i < framebuf_len && framebufs[i] == 0) { i += 2; };
	if (i < framebuf_len) {
		*fbid = framebufs[i];
		*tid = framebufs[i + 1];
		framebufs[i] = 0;
		framebufs[i + 1] = 0;
	} else {
		glGenFramebuffers(1, fbid);
		glGenTextures(1, tid);
	}

	glBindTexture(GL_TEXTURE_2D, *tid);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

	glBindFramebuffer(GL_FRAMEBUFFER, *fbid);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *tid, 0);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) caml_failwith("framebuffer status error");	
}

void framebuf_return_id(GLuint fbid, GLuint tid) {
	//maybe release texture memory when returting to pool?
	int i = 0;
	while (i < framebuf_len && framebufs[i] != 0) { i += 2; };
	if (i < framebuf_len) {
		framebufs[i] = fbid;
		framebufs[i + 1] = tid;
	}
	else {
		framebufs = realloc(framebufs,sizeof(GLuint) * (framebuf_len + 2));
		framebufs[framebuf_len] = fbid;
		framebufs[framebuf_len + 1] = tid;
		framebuf_len += 2;
	}
}
