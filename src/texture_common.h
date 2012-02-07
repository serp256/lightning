
#ifndef __TEXTURE_COMMON_H__

#define __TEXTURE_COMMON_H__

#ifdef ANDROID
#include <GLES/gl2.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#else
#define GL_GLEXT_PROTOTYPES
#include <SDL_opengl.h>
#endif
#endif

#include <caml/mlvalues.h>
#include "light_common.h"

int nextPowerOfTwo(int number);

typedef enum 
{
    SPTextureFormatRGBA,
    SPTextureFormatRGB,
    SPTextureFormatAlpha,
    SPTextureFormatPvrtcRGB2,
    SPTextureFormatPvrtcRGBA2,
    SPTextureFormatPvrtcRGB4,
    SPTextureFormatPvrtcRGBA4,
    SPTextureFormat565,
    SPTextureFormat5551,
    SPTextureFormat4444
} SPTextureFormat;

typedef struct {
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


value createGLTexture(GLuint mTextureID, textureInfo *tInfo);

#endif
