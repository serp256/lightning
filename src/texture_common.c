

#ifdef ANDROID
#include <GLES/gl.h>
#else 
#ifdef IOS
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#else
#ifdef __APPLE__
#include <OpenGL/gl.h>
#else // this is linux
#include <GL/gl.h>
#endif
#endif
#endif

#include <stdio.h>
#include "texture_common.h"
#include <caml/memory.h>
#include <caml/bigarray.h>
#include <caml/custom.h>

#define MAXTEXMEMORY 73400320

int nextPowerOfTwo(int number) {
	int result = 1;
	while (result < number) result *= 2;
	return result;
}

#define MAX(p1,p2) p1 > p2 ? p1 : p2

typedef struct {
	GLenum glTexType;
	GLenum glTexFormat;
	int bitsPerPixel;
	int compressed;
} texParams;


int textureParams(textureInfo *tInfo,texParams *p) {
    switch (tInfo->format)
    {
        case SPTextureFormatRGBA:
            p->glTexFormat = GL_RGBA;
            break;
				case SPTextureFormatRGB:
						p->glTexFormat = GL_RGB;
						break;
        case SPTextureFormatAlpha:
            p->glTexFormat = GL_ALPHA;
            break;
        case SPTextureFormatPvrtcRGBA2:
#ifdef IOS
            p->compressed = 1;
            p->bitsPerPixel = 2;
            p->glTexFormat = GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
            break;
#else
						return 0;
#endif
        case SPTextureFormatPvrtcRGB2:
#ifdef IOS
            p->compressed = 1;
            p->bitsPerPixel = 2;
            p->glTexFormat = GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            break;
#else
						return 0;
#endif
        case SPTextureFormatPvrtcRGBA4:
#ifdef IOS
            p->compressed = 1;
            p->bitsPerPixel = 4;
            p->glTexFormat = GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            break;
#else 
						return 0;
#endif
        case SPTextureFormatPvrtcRGB4:
#ifdef IOS
            p->compressed = 1;
            p->bitsPerPixel = 4;
            p->glTexFormat = GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            break;
#else
						return 0;
#endif
        case SPTextureFormat565:
            p->bitsPerPixel = 16;
            p->glTexFormat = GL_RGB;
            p->glTexType = GL_UNSIGNED_SHORT_5_6_5;
            break;
        case SPTextureFormat5551:
            p->bitsPerPixel = 16;                    
            p->glTexFormat = GL_RGBA;
            p->glTexType = GL_UNSIGNED_SHORT_5_5_5_1;                    
            break;
        case SPTextureFormat4444:
            p->bitsPerPixel = 16;
            p->glTexFormat = GL_RGBA;
            p->glTexType = GL_UNSIGNED_SHORT_4_4_4_4;                    
            break;
    }
		return 1;
}

#define TEXID(v) ((GLuint*)Data_custom_val(v))


value ml_glid_of_textureID(value textureID) {
	return Val_int(*TEXID(textureID));
}

void ml_bind_texture(value texid) {
	GLuint textureID = *TEXID(texid);
	glBindTexture(GL_TEXTURE_2D,textureID);
}

static void texid_finalize(value texid) {
	GLuint textureID = *TEXID(texid);
	printf("finalize texture: %d\n",textureID);
	glDeleteTextures(1,&textureID);
}

static int texid_compare(value texid1,value texid2) {
	GLuint t1 = *TEXID(texid1);
	GLuint t2 = *TEXID(texid2);
	if (t1 == t2) return 0;
	else {
		if (t1 < t2) return -1;
		return 1;
	}
}

struct custom_operations texid_ops = {
  "pointer to texture id",
  texid_finalize,
  texid_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


// make it custom 
value createGLTexture(value texid,textureInfo *tInfo) {
    int mRepeat = 0;    
    
		texParams params;
    params.glTexType = GL_UNSIGNED_BYTE;
    params.bitsPerPixel = 8;
    params.compressed = 0;
    //unsigned int mTextureID;
		if (!textureParams(tInfo,&params)) return 0;
    
		GLuint mTextureID;
		if (texid == 1) glGenTextures(1, &mTextureID);
		else mTextureID = *TEXID(Field(texid,0));
    glBindTexture(GL_TEXTURE_2D, mTextureID);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    
		int level;
    if (!params.compressed)
    {       
        if (tInfo->numMipmaps > 0 || tInfo->generateMipmaps)
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
        else
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        if (tInfo->numMipmaps == 0 && tInfo->generateMipmaps)
            glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);  
        
        int levelWidth = tInfo->width;
        int levelHeight = tInfo->height;
        unsigned char *levelData = tInfo->imgData;
        

        for (level=0; level<= tInfo->numMipmaps; ++level)
        {                    
            int size = levelWidth * levelHeight * params.bitsPerPixel / 8;
            glTexImage2D(GL_TEXTURE_2D, level, params.glTexFormat, levelWidth, levelHeight, 0, params.glTexFormat, params.glTexType, levelData);
            levelData += size;
            levelWidth  /= 2; 
            levelHeight /= 2;
        }            
    }
    else
    {
        // 'generateMipmaps' not supported for compressed textures
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tInfo->numMipmaps == 0 ? GL_LINEAR : GL_LINEAR_MIPMAP_NEAREST);
        
        int levelWidth = tInfo->width;
        int levelHeight = tInfo->height;
        unsigned char *levelData = tInfo->imgData;
        
        for (level=0; level<= tInfo->numMipmaps; ++level)
        {                    
						int size = MAX(32, levelWidth * levelHeight * params.bitsPerPixel / 8);
            glCompressedTexImage2D(GL_TEXTURE_2D, level, params.glTexFormat, levelWidth, levelHeight, 0, size, levelData);
            levelData += size;
            levelWidth  /= 2; 
            levelHeight /= 2;
        }
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
		value result;
		if (texid == 1) {
			printf("new texture of size: %d\n",tInfo->dataLen);
			result = caml_alloc_custom(&texid_ops, sizeof(GLuint), tInfo->dataLen, MAXTEXMEMORY);
			*TEXID(result) = mTextureID;
		} else result = Field(texid,0);
    return result;
};

CAMLprim value ml_loadTexture(value mlTexInfo, value imgData) {
	CAMLparam2(mlTexInfo,imgData);
	textureInfo tInfo;
	tInfo.format = Long_val(Field(mlTexInfo,0));
	tInfo.realWidth = (double)Long_val(Field(mlTexInfo,1));
	tInfo.width = Long_val(Field(mlTexInfo,2));
	tInfo.realHeight = (double)Long_val(Field(mlTexInfo,3));
	tInfo.height = Long_val(Field(mlTexInfo,4));
	tInfo.numMipmaps = Long_val(Field(mlTexInfo,5));
	tInfo.generateMipmaps = Int_val(Field(mlTexInfo,6));
	tInfo.premultipliedAlpha = Int_val(Field(mlTexInfo,7));
	tInfo.scale = Double_val(Field(mlTexInfo,8));
	if (imgData == 1) {
		tInfo.dataLen = 0;
		tInfo.imgData = NULL;
	} else {
		struct caml_ba_array *data = Caml_ba_array_val(Field(imgData,0));
		tInfo.dataLen = data->dim[0];
		tInfo.imgData = data->data;
	};
	value texID = createGLTexture(Field(mlTexInfo,9),&tInfo);
	if (!texID) caml_failwith("failed to load texture");
	Store_field(mlTexInfo,9,texID);
	CAMLreturn(mlTexInfo);
}
