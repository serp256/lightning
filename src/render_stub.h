#ifndef __RENDER_STUB_H_
#define __RENDER_STUB_H_

#ifdef ANDROID
#include <GLES/gl2.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
#else
#define GL_GLEXT_PROTOTYPES
#include <SDL/SDL_opengl.h>
#endif
#endif


#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/bigarray.h>
#include <caml/fail.h>

typedef struct 
{
  GLfloat r;
  GLfloat g;
  GLfloat b;
} color3F;

#define COLOR_PART_ALPHA(color)  (((color) >> 24) & 0xff)
#define COLOR_PART_RED(color)    (((color) >> 16) & 0xff)
#define COLOR_PART_GREEN(color)  (((color) >>  8) & 0xff)
#define COLOR_PART_BLUE(color)   ( (color)        & 0xff)
#define COLOR3F_FROM_INT(c) (color3F){(GLfloat)(COLOR_PART_RED(c)/255.),(GLfloat)(COLOR_PART_GREEN(c)/255.),(GLfloat)(COLOR_PART_BLUE(c)/255.)}

enum {
  lgUniformMVPMatrix,
	lgUniformAlpha,
  lgUniformSampler,
  lgUniform_MAX,
};

typedef struct {
	GLuint program;
	//GLint attributes[lgVertexAttrib_MAX];
	GLint std_uniforms[lgUniform_MAX];
	GLint *uniforms;
} sprogram;

typedef void (*filterRender)(sprogram *sp,void *data);
typedef void (*filterFinalize)(void *data);
typedef struct {
	filterRender render;
	filterFinalize finalize;
	void *data;
} filter;

#define FILTER(v) *((filter**)Data_custom_val(v))


/* vertex attribs */
enum {
  lgVertexAttrib_Position = 0,
  lgVertexAttrib_TexCoords = 1,
  lgVertexAttrib_Color = 2,
};  

/** vertex attrib flags */
enum {
  lgVertexAttribFlag_None    = 0,

  lgVertexAttribFlag_Position  = 1 << 0,
  lgVertexAttribFlag_TexCoords = 1 << 1,
  lgVertexAttribFlag_Color   = 1 << 2,
  
	lgVertexAttribFlag_PosColor = (lgVertexAttribFlag_Position | lgVertexAttribFlag_Color),
	lgVertexAttribFlag_PosColorTex = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_Color | lgVertexAttribFlag_TexCoords ),
	lgVertexAttribFlag_PosTex = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_TexCoords )
};

void lgGLEnableVertexAttribs( unsigned int flags );

typedef struct {
	GLuint frameBuffer;
	GLsizei width;
	GLsizei height;
} framebuffer_state; 

void get_framebuffer_state(framebuffer_state *s);
void set_framebuffer_state(framebuffer_state *s);



void checkGLErrors(char *where);

#endif
