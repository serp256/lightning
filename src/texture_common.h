
#ifndef __TEXTURE_COMMON_H__
#define __TEXTURE_COMMON_H__

#ifdef ANDROID
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <sys/types.h>
#else
#include <OpenGL/gl.h>
#define GL_GLEXT_PROTOTYPES
#include <sys/types.h>
#endif
#endif

#include <caml/mlvalues.h>
#include <zlib.h>
#include "light_common.h"

int nextPowerOfTwo(int number);
unsigned long nextPOT(unsigned long x);

struct tex {
	GLuint tid;
	char path[255];// remove this then release
	int mem;
};

#define TEXTURE_ID(v) ((struct tex*)Data_custom_val(v))->tid

//extern GLuint boundTextureID;
void setPMAGLBlend ();
void enableSeparateBlend ();
void disableSeparateBlend ();
void setNotPMAGLBlend ();
void lgGLBindTexture(GLuint textureID, int pma);
void lgGLBindTextures(GLuint textureID, GLuint textureID1, int newPMA);
void lgResetBoundTextures();
value alloc_texture_id(GLuint textureID, unsigned int dataLen);
void update_texture_id(value mlTextureID,GLuint textureID);


typedef enum 
{
	LTextureFormatRGBA,
	LTextureFormatRGB,
	LTextureFormatAlpha,
	LTextureFormatPvrtcRGB2,
	LTextureFormatPvrtcRGBA2,
	LTextureFormatPvrtcRGB4,
	LTextureFormatPvrtcRGBA4,
	LTextureFormat565,
	LTextureFormat5551,
	LTextureFormat4444,
	LTextureFormatPallete
} LTextureFormat;

typedef struct {
	//char path[255];
	int format;
	unsigned int width;
	double realWidth;
	unsigned int height;
	double realHeight;
	int numMipmaps;
	int generateMipmaps;
	int premultipliedAlpha;
	float scale;
	unsigned int dataLen;
	unsigned char* imgData;
} textureInfo;


int loadPlxPtr(gzFile fptr,textureInfo *tInfo);
int loadPlxFile(const char *path,textureInfo *tInfo);
int loadAlphaPtr(gzFile fptr,textureInfo *tInfo);
int loadAlphaFile(const char *path,textureInfo *tInfo);

value createGLTexture(value oldTextureID, textureInfo *tInfo,value filter);



#define OPTION_INT(v) v == 1 ? 0 : Long_val(Field(v,0))

#define ML_TEXTURE_INFO(mlTex,textureID,tInfo) \
	mlTex = caml_alloc_tuple(8);\
	if ((tInfo->format & 0xFFFF) != LTextureFormatPallete) \
		Field(mlTex,0) = Val_int(tInfo->format);\
	else { Store_field(mlTex,0,caml_alloc(1,0)); Field(Field(mlTex,0),0) = Val_int(tInfo->format >> 16);} \
	Field(mlTex,1) = Val_long((unsigned int)tInfo->realWidth);\
	Field(mlTex,2) = Val_long(tInfo->width);\
	Field(mlTex,3) = Val_long((unsigned int)tInfo->realHeight);\
	Field(mlTex,4) = Val_long(tInfo->height);\
	Field(mlTex,5) = Val_int(tInfo->premultipliedAlpha);\
	Field(mlTex,6) = Val_long(tInfo->dataLen); \
	Field(mlTex,7) = textureID;





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


#define RENDERBUFFER(v) ((renderbuffer_t*)Data_custom_val(v))


int create_renderbuffer(double width,double height, renderbuffer_t *r,GLenum filter);
int clone_renderbuffer(renderbuffer_t *sr,renderbuffer_t *dr,GLenum filter);
void delete_renderbuffer(renderbuffer_t *rb);

#endif
