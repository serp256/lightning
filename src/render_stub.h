#ifndef __RENDER_STUB_H_
#define __RENDER_STUB_H_

#ifdef ANDROID
#define GL_GLEXT_PROTOTYPES
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
#else
#define GL_GLEXT_PROTOTYPES
#include <OpenGL/gl.h>
#endif
#endif


#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/bigarray.h>
#include <caml/fail.h>

#include "light_common.h"

void setPMAGLBlend();
void setNotPMAGLBlend();

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

typedef struct
{
  GLfloat x;
  GLfloat y;
} vertex2F;


typedef struct 
{
  GLubyte r;
  GLubyte g;
  GLubyte b;
  GLubyte a;
} color4B;

typedef struct _ccTex2F {
   GLfloat u;
   GLfloat v;
} tex2F;

typedef struct 
{ 
  //! vertices (2F)
  vertex2F    v;
  //! colors (4B)   
  color4B   c;
  //! tex coords (2F)
  tex2F     tex;
} lgTexVertex;

typedef struct
{
  //! top left
  lgTexVertex tl;
  //! bottom left
  lgTexVertex bl;
  //! top right
  lgTexVertex tr;
  //! bottom right
  lgTexVertex br;
} lgTexQuad;


typedef struct
{
	lgTexQuad quad;
	GLuint textureID;
	GLuint pallete;
	unsigned char pma;
} lgImage;

#define TexVertexSize sizeof(lgTexVertex)

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
	lgVertexAttribFlag_PosTexColor = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_Color | lgVertexAttribFlag_TexCoords ),
	lgVertexAttribFlag_PosTex = ( lgVertexAttribFlag_Position | lgVertexAttribFlag_TexCoords )
};

void lgGLEnableVertexAttribs( unsigned int flags );

typedef struct {
	GLuint framebuffer;
	GLsizei viewport[4];
} framebuffer_state; 

void get_framebuffer_state(framebuffer_state *s);
void set_framebuffer_state(framebuffer_state *s);


void render_clear_cached_values ();


#endif
