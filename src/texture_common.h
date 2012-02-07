
#ifndef __TEXTURE_COMMON_H__
#define __TEXTURE_COMMON_H__

#ifdef ANDROID
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#else 
#ifdef IOS
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#else
#define GL_GLEXT_PROTOTYPES
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

#endif
