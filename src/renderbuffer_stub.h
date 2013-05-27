#ifndef __RENDERBUFFER_STUB_H_
#define __RENDERBUFFER_STUB_H_

#include "light_common.h"
#include "texture_common.h"

typedef struct {
	GLfloat x;
	GLfloat y;
	GLfloat width;
	GLfloat height;
} clipping;

typedef struct {
	GLsizei x;
	GLsizei y;
	GLsizei w;
	GLsizei h;
} viewport;

#define IS_CLIPPING(clp) (clp.x == 0. && clp.y == 0. && clp.width == 1. && clp.height == 1.)

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
	GLuint framebuffer;
	GLsizei viewport[4];
} framebuffer_state; 

void get_framebuffer_state(framebuffer_state *s);
void set_framebuffer_state(framebuffer_state *s);

int create_renderbuffer(GLuint tid, int x, int y, double width, double height, renderbuffer_t *r);
value ml_create_renderbuffer_tex();

// int create_renderbuffer(GLuint texId, double vp_x, double vp_y, double width, double height, renderbuffer_t *r,GLenum filter);
// int create_renderbuffer(double width,double height, renderbuffer_t *r,GLenum filter);
// int clone_renderbuffer(renderbuffer_t *sr,renderbuffer_t *dr,GLenum filter);
// void delete_renderbuffer(renderbuffer_t *rb);

#endif
