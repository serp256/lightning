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


#endif
