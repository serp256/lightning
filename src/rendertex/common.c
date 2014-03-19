#include "common.h"
#include <kazmath/GL/matrix.h>

struct framebuf_state {
	GLuint fbid;
	viewport viewport;
	struct framebuf_state *prev;
};

typedef struct framebuf_state framebuf_state_t;

static framebuf_state_t *framebuf_stack = NULL;

void framebuf_push(GLuint fbid, viewport *vp, int8_t apply) {
	framebuf_state_t *state = (framebuf_state_t*)malloc(sizeof(framebuf_state_t));

	state->fbid = fbid;
	state->viewport = *vp;
	state->prev = framebuf_stack;
	framebuf_stack = state;

	if (apply & FRAMEBUF_APPLY_BUF) glBindFramebuffer(GL_FRAMEBUFFER, fbid);
	if (apply & FRAMEBUF_APPLY_VIEWPORT) glViewport(vp->x,vp->y,vp->w,vp->h);
}

GLuint framebuf_restore(int8_t apply_viewport) {
	glBindFramebuffer(GL_FRAMEBUFFER, framebuf_stack->fbid);
	if (apply_viewport) glViewport(framebuf_stack->viewport.x, framebuf_stack->viewport.y, framebuf_stack->viewport.w, framebuf_stack->viewport.h);
}

void framebuf_pop() {
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

static int tex_num = 0;
static GLuint *texs = NULL;

GLuint inline tex_get_id() {
	GLuint tid = 0;
	int i = 0;
	while ((i < tex_num) && (texs[i] == 0)) {i++;};
	if (i < tex_num) {
		tid = texs[i];
		texs[i] = 0;
		glBindTexture(GL_TEXTURE_2D, tid);
	} else {
		glGenTextures(1,&tid);
		glBindTexture(GL_TEXTURE_2D, tid);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	};
	return tid;
}

void inline tex_return_id(GLuint tid) {
	int i = 0;
	while (i < tex_num && texs[i] != 0) {i++;};
	if (i < tex_num) {
		texs[i] = tid;
	} else {
		texs = realloc(texs,sizeof(GLuint)*(tex_num + 1));
		texs[tex_num] = tid;
		++tex_num;
	}
}

static int framebuf_num = 0;
static GLuint *framebufs = NULL;

GLuint framebuf_get_id() {
	GLuint fbid = 0;
	int i = 0;
	while ((i < framebuf_num) && (framebufs[i] == 0)) {i++;};
	if (i < framebuf_num) {
		fbid = framebufs[i];
		framebufs[i] = 0;
	} else glGenFramebuffers(1,&fbid);
	PRINT_DEBUG("get framebuffer: %d",fbid);
	return fbid;
}

void framebuf_return_id(GLuint fbid) {
	int i = 0;
	while (i < framebuf_num && framebufs[i] != 0) {i++;};
	if (i < framebuf_num) framebufs[i] = fbid;
	else {
		framebufs = realloc(framebufs,sizeof(GLuint)*(framebuf_num + 1));
		framebufs[framebuf_num] = fbid;
		++framebuf_num;
	}
	PRINT_DEBUG("back framebuffer: %d",fbid);
}
