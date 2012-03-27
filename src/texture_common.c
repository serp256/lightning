#include <stdio.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/custom.h>

#include "texture_common.h"


static int MAX_TEXTURE_MEMORY = 62914560;

void ml_texture_id_delete(value textureID) {
	GLuint tid = *TEXTURE_ID(textureID);
	PRINT_DEBUG("delete texture: %d\n",tid);
	if (tid) {
		glDeleteTextures(1,&tid);
		*TEXTURE_ID(textureID) = 0;
	};
}

static void textureID_finalize(value texid) {
	GLuint textureID = *TEXTURE_ID(texid);
	PRINT_DEBUG("finalize texture: <%d>\n",textureID);
	if (textureID) glDeleteTextures(1,&textureID);
}

static int textureID_compare(value texid1,value texid2) {
	GLuint t1 = *TEXTURE_ID(texid1);
	GLuint t2 = *TEXTURE_ID(texid2);
	if (t1 == t2) return 0;
	else {
		if (t1 < t2) return -1;
		return 1;
	}
}

struct custom_operations textureID_ops = {
  "pointer to texture id",
  textureID_finalize,
  textureID_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

#define Store_textureID(mlTextureID,tid,dataLen) \
	mlTextureID = caml_alloc_custom(&textureID_ops, sizeof(GLuint), dataLen, MAX_TEXTURE_MEMORY); \
	*TEXTURE_ID(mlTextureID) = tid;

value alloc_texture_id(GLuint textureID, int dataLen) {
	value mlTextureID;
	Store_textureID(mlTextureID,textureID,dataLen);
	return mlTextureID;
}

value ml_texture_id_zero() {
	value mlTextureID;
	Store_textureID(mlTextureID,0,0);
	return mlTextureID;
}

value ml_texture_id_to_int32(value textureID) {
	GLuint tid = *TEXTURE_ID(textureID);
	return (caml_copy_int32(tid));
}

GLuint boundTextureID = 0;
int PMA = -1;
int separateBlend = 0;
GLuint boundTextureID1 = 0;

void setPMAGLBlend () {
	if (PMA != 1) {
		glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
		PMA = 1;
	};
}

void setNotPMAGLBlend () {
	if (PMA != 0) {
		if (separateBlend) {
			//printf("set separate not pma blend\n");
			glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
		} else {
			//printf("set odinary not pma blend\n");
			glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		};
		PMA = 0;
	};
}

void enableSeparateBlend () {
	separateBlend = 1;
	if (PMA == 0) PMA = -1;
}
void disableSeparateBlend () {
	separateBlend = 0;
	if (PMA == 0) PMA = -1;
}

void lgGLBindTexture(GLuint textureID, int newPMA) {
	if (boundTextureID != textureID) {
		glBindTexture(GL_TEXTURE_2D,textureID);
		boundTextureID = textureID;
	};
	if (newPMA != PMA) {
		if (newPMA) glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA); else 
			if (separateBlend)
				glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
			else
				glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		PMA = newPMA;
	};
	if (boundTextureID1) {
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D,0);
		//glDisable(GL_TEXTURE_2D);
		glActiveTexture(GL_TEXTURE0);
		boundTextureID1 = 0;
	};
	checkGLErrors("bind texture");
};

void lgGLBindTextures(GLuint textureID, GLuint textureID1, int newPMA) {
	if (boundTextureID != textureID) {
		glBindTexture(GL_TEXTURE_2D,textureID);
		boundTextureID = textureID;
	};
	if (newPMA != PMA) {
		if (newPMA) glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA); else 
			if (separateBlend)
				glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
			else
				glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		PMA = newPMA;
	};
	if (boundTextureID1 != textureID1) {
		glActiveTexture(GL_TEXTURE1);
		checkGLErrors("active texture 1");
		glBindTexture(GL_TEXTURE_2D,textureID1);
		boundTextureID1 = textureID1;
		glActiveTexture(GL_TEXTURE0);
	}
	checkGLErrors("bind textures");
}

void lgResetBoundTextures() {
	boundTextureID = 0;
	if (boundTextureID1) {
		glActiveTexture(GL_TEXTURE1);
		//glDisable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D,0);
		glActiveTexture(GL_TEXTURE0);
		boundTextureID1 = 0;
	};
}


int nextPowerOfTwo(int number) {
	int result = 1;
	while (result < number) result *= 2;
	return result;
}

int loadPlxFile(const char *path,textureInfo *tInfo) {
	fprintf(stderr,"LOAD PLX: %s\n",path);
	// load idx
	FILE *fptr = fopen(path, "rb"); 
	if (!fptr) { fprintf(stderr,"can't open %s file",path); return 2;};
	unsigned char pallete;
	fread(&pallete,sizeof(pallete),1,fptr);
	unsigned int size;
	fread(&size,sizeof(size),1,fptr);
	unsigned short width = size & 0xFFFF;
	unsigned short height = size >> 16;
	size_t dataSize = width * height * 2;
	unsigned char *idxdata = malloc(dataSize);
	if (!fread(idxdata,dataSize,1,fptr)) {fprintf(stderr,"can't read PLX %s data\n",path);return 1;};
	fclose(fptr);


	tInfo->format = LTextureFormatPallete;
	tInfo->format = (pallete << 16) | LTextureFormatPallete;
	tInfo->width = tInfo->realWidth = width;
	tInfo->height = tInfo->realHeight = height;
	tInfo->numMipmaps = 0;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = 0;
	tInfo->scale = 1.;
	tInfo->dataLen = dataSize;
	tInfo->imgData = idxdata;

	return 0;
	/*
	GLuint tid;
	glGenTextures(1, &tid);
	glBindTexture(GL_TEXTURE_2D,tid);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width, height, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, idxdata);
	checkGLErrors("glTexImage2D idx");
	glBindTexture(GL_TEXTURE_2D,0);
	*/

};

int loadAlphaFile(const char *path,textureInfo *tInfo) {
	fprintf(stderr,"LOAD ALPHA: '%s'\n",path);
	FILE *fptr = fopen(path, "rb"); 
	if (!fptr) { fprintf(stderr,"can't open %s file",path); fclose(fptr); return 2;};
	unsigned int size;
	fread(&size,sizeof(size),1,fptr);
	unsigned short width = size & 0xFFFF;
	unsigned short height = size >> 16;
	size_t dataSize = width * height;
	unsigned char *data = malloc(dataSize);
	if (!fread(data,dataSize,1,fptr)) {fprintf(stderr,"can't read ALPHA %s data\n",path);free(data);fclose(fptr);return 1;};
	fclose(fptr);

	tInfo->format = LTextureFormatAlpha;
	tInfo->width = tInfo->realWidth = width;
	tInfo->height = tInfo->realHeight = height;
	tInfo->numMipmaps = 0;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = 1;
	tInfo->scale = 1.;
	tInfo->dataLen = dataSize;
	tInfo->imgData = data;

	return 0;
}

#define MAX(p1,p2) p1 > p2 ? p1 : p2

typedef struct {
	GLenum glTexType;
	GLenum glTexFormat;
	int bitsPerPixel;
	int compressed;
} texParams;


static inline int textureParams(textureInfo *tInfo,texParams *p) {
    switch (tInfo->format & 0xFFFF)
    {
        case LTextureFormatRGBA:
            p->glTexFormat = GL_RGBA;
            break;
				case LTextureFormatRGB:
						p->glTexFormat = GL_RGB;
						break;
        case LTextureFormatAlpha:
            p->glTexFormat = GL_ALPHA;
						p->bitsPerPixel = 1;
            break;
				case LTextureFormatPallete:
						p->glTexFormat = GL_LUMINANCE_ALPHA;
            p->bitsPerPixel = 2;
						break;
        case LTextureFormatPvrtcRGBA2:
#if (defined IOS || defined ANDROID)
            p->compressed = 1;
            p->bitsPerPixel = 2;
            p->glTexFormat = GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
            break;
#else
						return 0;
#endif
        case LTextureFormatPvrtcRGB2:
#if (defined IOS || defined ANDROID)
            p->compressed = 1;
            p->bitsPerPixel = 2;
            p->glTexFormat = GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            break;
#else
						return 0;
#endif
        case LTextureFormatPvrtcRGBA4:
#if (defined IOS || defined ANDROID)
            p->compressed = 1;
            p->bitsPerPixel = 4;
            p->glTexFormat = GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            break;
#else 
						return 0;
#endif
        case LTextureFormatPvrtcRGB4:
#if (defined IOS || defined ANDROID)
            p->compressed = 1;
            p->bitsPerPixel = 4;
            p->glTexFormat = GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            break;
#else
						return 0;
#endif
        case LTextureFormat565:
            p->bitsPerPixel = 16;
            p->glTexFormat = GL_RGB;
            p->glTexType = GL_UNSIGNED_SHORT_5_6_5;
            break;
        case LTextureFormat5551:
            p->bitsPerPixel = 16;                    
            p->glTexFormat = GL_RGBA;
            p->glTexType = GL_UNSIGNED_SHORT_5_5_5_1;                    
            break;
        case LTextureFormat4444:
            p->bitsPerPixel = 16;
            p->glTexFormat = GL_RGBA;
            p->glTexType = GL_UNSIGNED_SHORT_4_4_4_4;                    
            break;
    }
		return 1;
}


/*
void ml_delete_texture(value textureID) {
	PRINT_DEBUG("delete texture <%d>",Int_val(textureID));
	GLuint texID = Long_val(textureID);
	glDeleteTextures(1,&texID);
}
*/


value createGLTexture(value oldTextureID,textureInfo *tInfo) {
    //int mRepeat = 0;    
    
		texParams params;
    params.glTexType = GL_UNSIGNED_BYTE;
    params.bitsPerPixel = 8;
    params.compressed = 0;
    //unsigned int mTextureID;
		if (!textureParams(tInfo,&params)) return 0;
    
		GLuint textureID;
		value mlTextureID;
		if (oldTextureID == 1) { // ocaml None
			glGenTextures(1, &textureID);
			PRINT_DEBUG("glGenTextures: <%d>",textureID);
			checkGLErrors("glGenTexture");
			Store_textureID(mlTextureID,textureID,tInfo->dataLen);
		} else {
			// FIXME: check if it's correct
			mlTextureID = Field(oldTextureID,0);
			textureID = *TEXTURE_ID(mlTextureID);
		}
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); 
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); 
    
		int level;
    if (!params.compressed)
    {       
        if (tInfo->numMipmaps > 0 || tInfo->generateMipmaps)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
        else
            //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        
        if (tInfo->numMipmaps == 0 && tInfo->generateMipmaps) glGenerateMipmap(GL_TEXTURE_2D);
        
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
		boundTextureID = 0;
    return mlTextureID;
};

void ml_texture_set_filter(value textureID,value filter) {
	GLuint tid = *TEXTURE_ID(textureID);
	glBindTexture(GL_TEXTURE_2D,tid);
	boundTextureID = tid;
	switch (Int_val(filter)) {
		case 0: 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			break;
		case 1:
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			break;
		default: break;
	};
}


value ml_load_texture(value oldTextureID, value oTInfo) {
	CAMLparam0();
	CAMLlocal1(mlTex);
	textureInfo *tInfo = (textureInfo*)oTInfo;
	GLuint textureID = createGLTexture(oldTextureID,(textureInfo*)tInfo);
	if (!textureID) caml_failwith("failed to load texture");
	ML_TEXTURE_INFO(mlTex,textureID,tInfo);
	CAMLreturn(mlTex);
}

void ml_free_image_info(value tInfo) {
	free(((textureInfo*)tInfo)->imgData);
	free((textureInfo*)tInfo);
}

value ml_rendertexture_create(value format, value color, value alpha, value width,value height) {
	CAMLparam0();
	CAMLlocal1(mlTextureID);
	GLuint mTextureID;
	checkGLErrors("start create rendertexture");
	glGenTextures(1, &mTextureID);
	lgGLBindTexture(mTextureID,PMA);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); 
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); 
	int w = Long_val(width),h = Long_val(height);
	PRINT_DEBUG("create rtexture: [%d:%d]\n",w,h);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	checkGLErrors("tex image 2d for framebuffer %d:%d",w,h);
	glBindTexture(GL_TEXTURE_2D,0);
	boundTextureID = 0;
	GLuint mFramebuffer;
	GLint oldBuffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING,&oldBuffer);
	glGenFramebuffers(1, &mFramebuffer);
	PRINT_DEBUG("generated new framebuffer: %d\n",mFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
	checkGLErrors("bind framebuffer");
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mTextureID,0);
	checkGLErrors("framebuffer texture");
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		PRINT_DEBUG("framebuffer status: %d\n",glCheckFramebufferStatus(GL_FRAMEBUFFER));
		caml_failwith("failed to create frame buffer for render texture");
	};
	//color3F c = COLOR3F_FROM_INT(Int_val(color));
	//glClearColor(c.r,c.g,c.b,(GLclampf)Double_val(alpha));
	//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glBindFramebuffer(GL_FRAMEBUFFER,oldBuffer);
	//printf("old buffer: %d\n",oldBuffer);
	Store_textureID(mlTextureID,mTextureID,w * h * 4);
	value result = caml_alloc_small(2,0);
	Field(result,0) = Val_long(mFramebuffer);
	Field(result,1) = mlTextureID;
	CAMLreturn(result);
};

void ml_resize_texture(value textureID,value width,value height) {
	GLuint mTextureID = *TEXTURE_ID(textureID);
	glBindTexture(GL_TEXTURE_2D, mTextureID);
	boundTextureID = 0;
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Long_val(width),Long_val(height),0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
}

/*
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
	value texID = createGLTexture(Long_val(Field(mlTexInfo,9)),&tInfo);
	if (!texID) caml_failwith("failed to load texture");
	Store_field(mlTexInfo,9,Val_long(texID));
	CAMLreturn(mlTexInfo);
}
*/



