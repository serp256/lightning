
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
#define GL_GLEXT_PROTOTYPES
#include <SDL_surface.h>
#include <SDL_opengl.h>
#include <sys/types.h>
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
#ifdef SDL
	SDL_Surface *surface;
#endif
	unsigned int dataLen;
	unsigned char* imgData;
} textureInfo;


value createGLTexture(GLuint mTextureID, textureInfo *tInfo);


// --- PVR structs & enums -------------------------------------------------------------------------

#define PVRTEX_IDENTIFIER 0x21525650 // = the characters 'P', 'V', 'R'

typedef struct
{
  uint headerSize;          // size of the structure
  uint height;              // height of surface to be created
  uint width;               // width of input surface
  uint numMipmaps;          // number of mip-map levels requested
  uint pfFlags;             // pixel format flags
  uint textureDataSize;     // total size in bytes
  uint bitCount;            // number of bits per pixel
  uint rBitMask;            // mask for red bit
  uint gBitMask;            // mask for green bits
  uint bBitMask;            // mask for blue bits
  uint alphaBitMask;        // mask for alpha channel
  uint pvr;                 // magic number identifying pvr file
  uint numSurfs;            // number of surfaces present in the pvr
} PVRTextureHeader;

enum PVRPixelType
{
  OGL_RGBA_4444 = 0x10,
  OGL_RGBA_5551,
  OGL_RGBA_8888,
  OGL_RGB_565,
  OGL_RGB_555,
  OGL_RGB_888,
  OGL_I_8,
  OGL_AI_88,
  OGL_PVRTC2,
  OGL_PVRTC4
};

#define OPTION_INT(v) v == 1 ? 0 : Long_val(Field(v,0))

#define ML_TEXTURE_INFO(mlTex,textureID,tInfo) \
	mlTex = caml_alloc_tuple(10);\
	Store_field(mlTex,0,Val_int(tInfo->format));\
	Store_field(mlTex,1,Val_int((unsigned int)tInfo->realWidth));\
	Store_field(mlTex,2,Val_int(tInfo->width));\
	Store_field(mlTex,3,Val_int((unsigned int)tInfo->realHeight));\
	Store_field(mlTex,4,Val_int(tInfo->height));\
	Store_field(mlTex,5,Val_int(tInfo->numMipmaps));\
	Store_field(mlTex,6,Val_int(1));\
	Store_field(mlTex,7,Val_int(tInfo->premultipliedAlpha));\
	Store_field(mlTex,8,caml_copy_double(tInfo->scale));\
	Store_field(mlTex,9,Val_long(textureID));


#endif
