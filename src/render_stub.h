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

typedef struct {
	filterFun f_fun;
	void *f_data;
} filter;

#define FILTER(v) *((filter**)Data_custom_val(v))

typedef void (*filterFun)(sprogram *sp,void *data);

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
	lgVertexAttribFlag_PosColorTex = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_Color | lgVertexAttribFlag_TexCoords )
	lgVertexAttribFlag_PosTex = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_TexCoords )
};

void lgGLEnableVertexAttribs( unsigned int flags );

struct framebuffer_state {
	GLuint frameBuffer;
	GLsizei width;
	GLsizei height;
}; 

void get_framebuffer_state(framebuffer_state *s);
void set_framebuffer_state(framebuffer_stat *s);
#endif
