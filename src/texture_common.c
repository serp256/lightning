#include <stdio.h>
#include <string.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/custom.h>
#include <math.h>

#include "texture_common.h"


static unsigned int total_tex_mem = 0;

extern uintnat caml_dependent_size;
#ifdef TEXTURE_LOAD
#define LOGMEM(op,tid,path,size) DEBUGMSG("TEXTURE MEMORY [%s] <%d:%s> %u -> %u:%u",op,tid,path,size,total_tex_mem,(unsigned int)caml_dependent_size)
static int allocated_textures = 0;
#else
#define LOGMEM(op,tid,path,size)
#endif




GLuint boundTextureID = 0;
int PMA = -1;
int separateBlend = 0;
GLuint boundTextureID1 = 0;

void ml_texture_id_delete(value textureID) {
	GLuint tid = TEXTURE_ID(textureID);
	if (tid) {
		glDeleteTextures(1,&tid);
		if (tid == boundTextureID) {boundTextureID = 0; PMA = -1;};
		if (tid == boundTextureID1) boundTextureID1 = 0;
		checkGLErrors("delete texture");
		struct tex *t = TEX(textureID);
		t->tid = 0;
		total_tex_mem -= t->mem;
#ifdef TEXTURE_LOAD
		LOGMEM("delete",tid,t->path,t->mem);
		if (!strcmp(t->path,"alloc")) {
			allocated_textures--;
			DEBUGMSG("ALLOCATED TEXTURES: %d",allocated_textures);
		}
#else
		LOGMEM("delete",tid,"path",t->mem);
#endif
		caml_free_dependent_memory(t->mem);
	};
}

void update_texture_id_size(value mlTextureID,unsigned int dataLen) {
	struct tex *t = TEX(mlTextureID);
	int diff = dataLen - t->mem;
	total_tex_mem += diff;
	if (diff > 0)
		caml_alloc_dependent_memory(diff);
	else caml_free_dependent_memory(-diff);
	t->mem = dataLen;
}

void update_texture_id(value mlTextureID,GLuint textureID) {
	TEX(mlTextureID)->tid = textureID;
}

static void textureID_finalize(value textureID) {
	GLuint tid = TEXTURE_ID(textureID);
	if (tid) {
		glDeleteTextures(1,&tid);
		if (tid == boundTextureID) {boundTextureID = 0; PMA = -1;};
		if (tid == boundTextureID1) boundTextureID1 = 0;
		checkGLErrors("finalize texture");
		struct tex *t = TEX(textureID);
		total_tex_mem -= t->mem;
		caml_free_dependent_memory(t->mem);
#ifdef TEXTURE_LOAD
		LOGMEM("finalize",tid,t->path,t->mem);
		if (!strcmp(t->path,"alloc")) {
			allocated_textures--;
			DEBUGMSG("ALLOCATED TEXTURES: %d",allocated_textures);
		};
#else
		LOGMEM("finalize",tid,"path",t->mem);
#endif
	};
}

static int textureID_compare(value texid1,value texid2) {
	GLuint t1 = TEXTURE_ID(texid1);
	GLuint t2 = TEXTURE_ID(texid2);
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

#ifdef TEXTURE_LOAD 
#define FILL_TEXTURE(texID,_path,dataLen) strcpy(_tex->path, _path); _tex->mem = dataLen; total_tex_mem += dataLen; LOGMEM("alloc",texID,_path,dataLen)
#else
#define FILL_TEXTURE(texID,_path,dataLen) _tex->mem = dataLen; total_tex_mem += dataLen
#endif

#define Store_textureID(mltex,texID,_path,dataLen) \
	caml_alloc_dependent_memory(dataLen); \
	mltex = caml_alloc_custom(&textureID_ops, sizeof(struct tex), dataLen, MAX_GC_MEM); \
	{struct tex *_tex = TEX(mltex); _tex->tid = texID; FILL_TEXTURE(texID,_path,dataLen);}
//*TEXTURE_ID(mlTextureID) = tid;


/*
value texture_id_alloc(GLuint textureID, unsigned int dataLen) {
	value mlTextureID;
	Store_textureID(mlTextureID,textureID,"alloc",dataLen);
#ifdef TEXTURE_LOAD
	allocated_textures++;
	DEBUGMSG("ALLOCATED TEXTURES: %d",allocated_textures);
#endif
	return mlTextureID;
}
*/

value ml_texture_id_zero() {
	value mlTextureID;
	Store_textureID(mlTextureID,0,"zero",0);
	return mlTextureID;
}

value ml_texture_id_to_int32(value textureID) {
	GLuint tid = TEXTURE_ID(textureID);
	return (caml_copy_int32(tid));
}


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
	PMA = -1;
}

void resetTextureIfBounded(GLuint tid) {
	if (tid == boundTextureID) {boundTextureID = 0; PMA = -1;};
	if (tid == boundTextureID1) boundTextureID1 = 0;
}


unsigned long nextPOT(unsigned long x)
{
    x = x - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >>16);
    return x + 1;
}


int nextPowerOfTwo(int number) {
	int result = 1;
	while (result < number) result *= 2;
	return result;
}


int loadPlxPtr(gzFile fptr,textureInfo *tInfo) {
	// load idx
	if (!fptr) return 2;
	unsigned char pallete;
	gzread(fptr,&pallete,1);
	unsigned int size;
	gzread(fptr,&size,sizeof(size));
	unsigned short width = size & 0xFFFF;
	unsigned short height = size >> 16;
	size_t dataSize = width * height * 2;
	unsigned char *idxdata = malloc(dataSize);
	if (gzread(fptr,idxdata,dataSize) < dataSize) {free(idxdata);gzclose(fptr);return 1;};
	gzclose(fptr);
	//fprintf(stderr,"PLX [%s] file with size %d:%d readed\n",path,width,height);


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

int loadPlxFile(const char *path,textureInfo *tInfo) {
	PRINT_DEBUG("LOAD PLX: %s\n",path);
	gzFile fptr = gzopen(path, "rb"); 
	return loadPlxPtr(fptr,tInfo);
};

int loadAlphaPtr(gzFile fptr,textureInfo *tInfo) {
	if (!fptr) { return 2;};
	unsigned int size;
	gzread(fptr,&size,sizeof(size));
	unsigned short width = size & 0xFFFF;
	unsigned short height = size >> 16;
	size_t dataSize = width * height;
	unsigned char *data = malloc(dataSize);
	if (gzread(fptr,data,dataSize) < dataSize) {free(data);gzclose(fptr);return 1;};
	gzclose(fptr);

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

int loadAlphaFile(const char *path,textureInfo *tInfo) {
	PRINT_DEBUG("LOAD ALPHA: '%s'",path);
	gzFile fptr = gzopen(path,"rb");
	return loadAlphaPtr(fptr,tInfo);
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
						p->bitsPerPixel = 3;
						break;
        case LTextureFormatAlpha:
            p->glTexFormat = GL_ALPHA;
						p->bitsPerPixel = 1;
            break;
				case LTextureFormatPallete:
						p->glTexFormat = GL_LUMINANCE_ALPHA;
            p->bitsPerPixel = 2;
            //p->glTexFormat = GL_ALPHA;
            //p->glTexType = GL_UNSIGNED_SHORT_4_4_4_4;                    
						break;

		case LTextureFormatETC1:
			p->compressed = 1;
			p->bitsPerPixel = 4;
			p->glTexFormat = GL_ETC1_RGB8_OES;

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

        case LTextureFormatDXT1:
#if (defined ANDROID)
        	p->compressed = 1;
        	p->bitsPerPixel = 4;        	
        	p->glTexFormat = GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;

            break;
#else
			return 0;
#endif

        case LTextureFormatDXT5:
#if (defined ANDROID)
        	p->compressed = 1;
        	p->bitsPerPixel = 8;        	
        	p->glTexFormat = 0x83F3;

            break;
#else
			return 0;
#endif

        case LTextureFormatATCRGB:
#if (defined ANDROID)
        	p->compressed = 1;
        	p->bitsPerPixel = 4;
        	p->glTexFormat = GL_ATC_RGB_AMD;

            break;
#else
			return 0;
#endif

        case LTextureFormatATCRGBAE:
#if (defined ANDROID)
        	p->compressed = 1;
        	p->bitsPerPixel = 8;
        	p->glTexFormat = GL_ATC_RGBA_EXPLICIT_ALPHA_AMD;

            break;
#else
			return 0;
#endif

        case LTextureFormatATCRGBAI:
#if (defined ANDROID)
        	p->compressed = 1;
        	p->bitsPerPixel = 8;
        	p->glTexFormat = GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD;

            break;
#else
			return 0;
#endif			

        case LTextureFormat565:
            p->bitsPerPixel = 2;
            p->glTexFormat = GL_RGB;
            p->glTexType = GL_UNSIGNED_SHORT_5_6_5;
            break;
        case LTextureFormat5551:
            p->bitsPerPixel = 2;                    
            p->glTexFormat = GL_RGBA;
            p->glTexType = GL_UNSIGNED_SHORT_5_5_5_1;                    
            break;
        case LTextureFormat4444:
            p->bitsPerPixel = 2;
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


value createGLTexture(value oldTextureID, textureInfo *tInfo, value filter) {
		texParams params;
    params.glTexType = GL_UNSIGNED_BYTE;
    params.bitsPerPixel = 4;
    params.compressed = 0;

	if (!textureParams(tInfo,&params)) return 0;

    if (!params.compressed && ((tInfo->format & 0xFFFF) == LTextureFormatRGBA || (nextPOT(tInfo->width) == tInfo->width && nextPOT(tInfo->height) == tInfo->height)))
			glPixelStorei(GL_UNPACK_ALIGNMENT,4);
		else
			glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    
		GLuint textureID;
		value mlTextureID;
		if (oldTextureID == 1) { // ocaml None
			glGenTextures(1, &textureID);
			PRINT_DEBUG("glGenTextures: <%d>",textureID);
			checkGLErrors("glGenTexture");
#ifdef TEXTURE_LOAD
			Store_textureID(mlTextureID,textureID,tInfo->path,tInfo->dataLen);
#else
			Store_textureID(mlTextureID,textureID,"",tInfo->dataLen);
#endif
		} else {
			// FIXME: check memory detecting incorrect
			mlTextureID = Field(oldTextureID,0);
			textureID = TEXTURE_ID(mlTextureID);
		}
    glBindTexture(GL_TEXTURE_2D, textureID);
    
		
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); 

		PRINT_DEBUG("filter is %d",filter);
		switch (Int_val(filter)) {
			case 0: 
				PRINT_DEBUG("SET NEAREST FILTER");
				if (tInfo->numMipmaps > 0 || tInfo->generateMipmaps)
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
				else
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
					break;
			case 1:
				PRINT_DEBUG("SET LINEAR FILTER");
				if (tInfo->numMipmaps > 0 || tInfo->generateMipmaps)
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
				else
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
					break;
			default: break;
		};
    
		int level;

		PRINT_DEBUG("params.compressed %d", params.compressed);

    if (!params.compressed)
    {
			/*
				if ((tInfo->format & 0xFFFF) == LTextureFormatRGBA || (nextPOT(tInfo->width) == tInfo->width && nextPOT(tInfo->height) == tInfo->height))
					glPixelStorei(GL_UNPACK_ALIGNMENT,4);
				else
					glPixelStorei(GL_UNPACK_ALIGNMENT,1);
			*/
				/*
        if (tInfo->numMipmaps > 0 || tInfo->generateMipmaps)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
        else
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						switch (Int_val(filter)) {
							case 0: 
								glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
								glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
								break;
							case 1:
								glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
								glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
								break;
							default: break;
						};
				*/
        
						PRINT_DEBUG("tInfo->numMipmaps %d", tInfo->numMipmaps);
						PRINT_DEBUG("tInfo->generateMipmaps %d", tInfo->generateMipmaps);

        if (tInfo->numMipmaps == 0 && tInfo->generateMipmaps) glGenerateMipmap(GL_TEXTURE_2D);
        
        int levelWidth = tInfo->width;
        int levelHeight = tInfo->height;
        unsigned char *levelData = tInfo->imgData;
        

        for (level=0; level <= tInfo->numMipmaps; ++level)
        {                    
			PRINT_DEBUG("LOAD DATA FOR LEVEL: %d",level);
            int size = levelWidth * levelHeight * params.bitsPerPixel;
            glTexImage2D(GL_TEXTURE_2D, level, params.glTexFormat, levelWidth, levelHeight, 0, params.glTexFormat, params.glTexType, levelData);
            levelData += size;
            levelWidth  /= 2; 
            levelHeight /= 2;
        }            
    }
    else
    {
        // 'generateMipmaps' not supported for compressed textures
        
        //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tInfo->numMipmaps == 0 ? GL_LINEAR : GL_LINEAR_MIPMAP_NEAREST);
        
		glPixelStorei(GL_UNPACK_ALIGNMENT,1);
        int levelWidth = tInfo->width;
        int levelHeight = tInfo->height;
        unsigned char *levelData = tInfo->imgData;
        
        PRINT_DEBUG("compressed %d", params.glTexFormat);

        for (level=0; level<= tInfo->numMipmaps; ++level)
        {                    
        	PRINT_DEBUG("level %d", level);
			int size = MAX(32, levelWidth * levelHeight * params.bitsPerPixel / 8);
            glCompressedTexImage2D(GL_TEXTURE_2D, level, params.glTexFormat, levelWidth, levelHeight, 0, size, levelData);
            levelData += size;
            levelWidth  /= 2; 
            levelHeight /= 2;
        }
    }
    
		checkGLErrors("create texture");
    glBindTexture(GL_TEXTURE_2D, 0);
		boundTextureID = 0;
    return mlTextureID;
};

void ml_texture_set_filter(value textureID,value filter) {
	GLuint tid = TEXTURE_ID(textureID);
	glBindTexture(GL_TEXTURE_2D,tid);
	boundTextureID = tid;
	switch (Int_val(filter)) {
		case 0: 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			break;
		case 1:
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			break;
		default: break;
	};
}


/*
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
*/


/* сделать рендер буфер
int create_renderbuffer(double width,double height, renderbuffer_t *r,GLenum filter) {
  GLuint rtid;
	GLuint iw = ceil(width);
	GLuint ih = ceil(height);
	//GLuint legalWidth = nextPowerOfTwo(iw);
	//GLuint legalHeight = nextPowerOfTwo(ih);
	GLuint legalWidth = nextPOT(iw);
	GLuint legalHeight = nextPOT(ih);
#if defined(IOS) || defined(ANDROID)
	if (legalWidth <= 8) {
    if (legalWidth > legalHeight) legalHeight = legalWidth;
    else 
      if (legalHeight > legalWidth * 2) legalWidth = legalHeight/2; 
			if (legalWidth > 16) legalWidth = 16;
	} else {
    if (legalHeight <= 8) legalHeight = 16 < legalWidth ? 16 : legalWidth;
	};
#endif
  glGenTextures(1, &rtid);
  glBindTexture(GL_TEXTURE_2D, rtid);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, legalWidth, legalHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	//checkGLErrors("create renderbuffer texture %d [%d:%d]",rtid,legalWidth,legalHeight);
  glBindTexture(GL_TEXTURE_2D,0);
  GLuint fbid;
  glGenFramebuffers(1, &fbid);
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rtid,0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    PRINT_DEBUG("framebuffer %d status: %d\n",fbid,glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return 1;
  };
  r->fbid = fbid;
  r->tid = rtid;
	r->vp = (viewport){(GLuint)((legalWidth - width)/2),(GLuint)((legalHeight - height)/2),(GLuint)width,(GLuint)height};
	r->clp = (clipping){(double)r->vp.x / legalWidth,(double)r->vp.y / legalHeight,(width / legalWidth),(height / legalHeight)};
  r->width = width;
  r->height = height;
	r->realWidth = legalWidth;
	r->realHeight = legalHeight;
	return 0;
}

int clone_renderbuffer(renderbuffer_t *sr, renderbuffer_t *dr,GLenum filter) {
	GLuint rtid;
  glGenTextures(1, &rtid);
  glBindTexture(GL_TEXTURE_2D, rtid);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, sr->realWidth, sr->realHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	//checkGLErrors("create renderbuffer texture %d [%d:%d]",rtid,legalWidth,legalHeight);
  glBindTexture(GL_TEXTURE_2D,0);
  GLuint fbid;
  glGenFramebuffers(1, &fbid);
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rtid,0);
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    PRINT_DEBUG("framebuffer %d status: %d\n",fbid,glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return 1;
  };
	dr->fbid = fbid;
	dr->tid = rtid;
	dr->vp = sr->vp;
	dr->clp = sr->clp;
	dr->width = sr->width;
	dr->height = sr->height;
	dr->realWidth = sr->realWidth;
	dr->realHeight = sr->realHeight;
	return 0;
}
*/



/* RENDERBUFFER 
 **********************
struct custom_operations renderbuffer_ops = {
  "pointer to a image",
	custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


void delete_renderbuffer(renderbuffer_t *rb) {
	glDeleteTextures(1,&rb->tid);
	glDeleteFramebuffers(1,&rb->fbid);
}

value renderbuffer_to_ml(value orb) {
	CAMLparam1(orb);
	CAMLlocal3(renderInfo,clip,clp);
	value mlTextureID = 0;
	renderbuffer_t *rb = RENDERBUFFER(orb);
	int s = rb->realWidth * rb->realHeight * 4;
	renderInfo = caml_alloc_tuple(5);
	Store_textureID(mlTextureID,rb->tid,"renderbuffer",s);
	Store_field(renderInfo,0,mlTextureID);
	Store_field(renderInfo,1,caml_copy_double(RENDERBUFFER(orb)->width));
	Store_field(renderInfo,2,caml_copy_double(RENDERBUFFER(orb)->height));
	if (!IS_CLIPPING(RENDERBUFFER(orb)->clp)) {
		clp = caml_alloc(4 * Double_wosize,Double_array_tag);
		rb = RENDERBUFFER(orb);
		Store_double_field(clp,0,rb->clp.x);
		Store_double_field(clp,1,rb->clp.y);
		Store_double_field(clp,2,rb->clp.width);
		Store_double_field(clp,3,rb->clp.height);
		clip = caml_alloc_small(1,0);
		Field(clip,0) = clp;
	} else clip = Val_unit;
	Store_field(renderInfo,3,clip);
	value kind = caml_alloc_small(1,0);
	Field(kind,0) = Val_true;
	Store_field(renderInfo,4,kind);
	value result = caml_alloc_small(2,0);
	Field(result,0) = orb;
	Field(result,1) = renderInfo;
	CAMLreturn(result);
}

value ml_renderbuffer_create(value format, value filter, value width,value height) {
	GLenum fltr;
	switch (Int_val(filter)) {
		case 0: 
			fltr = GL_NEAREST;
			break;
		case 1:
			fltr = GL_LINEAR;
			break;
		default: break;
	};
	GLint oldBuffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING,&oldBuffer);
	lgResetBoundTextures();
	value orb = caml_alloc_custom(&renderbuffer_ops,sizeof(renderbuffer_t),0,1);
	renderbuffer_t *rb = RENDERBUFFER(orb);
	if (create_renderbuffer(Double_val(width),Double_val(height),rb,fltr)) caml_failwith("can't create framebuffer");
	//fprintf(stderr,"create renderbuffer: %d:%d\n",rb->fbid,rb->tid);
	glBindFramebuffer(GL_FRAMEBUFFER,oldBuffer);
	// and create renderInfo here
	checkGLErrors("renderbuffer create");
	return renderbuffer_to_ml(orb);

}; */


/*
value ml_renderbuffer_clone(value orb) {
	CAMLparam1(orb);
	GLint oldBuffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING,&oldBuffer);
	lgResetBoundTextures();
	value orbc = caml_alloc_custom(&renderbuffer_ops,sizeof(renderbuffer_t),0,1);
	renderbuffer_t *rbc = RENDERBUFFER(orbc);
	if (clone_renderbuffer(RENDERBUFFER(orb),rbc,GL_LINEAR)) caml_failwith("can't clone renderbuffer");
	//fprintf(stderr,"clone renderbuffer: %d:%d\n",rbc->fbid,rbc->tid);
	glBindFramebuffer(GL_FRAMEBUFFER,oldBuffer);
	checkGLErrors("renderbuffer clone");
	CAMLreturn(renderbuffer_to_ml(orbc));
}
*/


/* VERY OLD
value ml_resize_texture(value textureID,value width,value height) {
	GLuint tid = TEXTURE_ID(textureID);
	int w = Long_val(width);
	int h = Long_val(height);
	glBindTexture(GL_TEXTURE_2D, tid);
	boundTextureID = 0;
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,w,h,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
	// хак с памятью 
	struct tex *_tex = TEX(textureID);
	_tex->tid = 0;
	_tex->mem = 0;
	Store_textureID(textureID,tid,w * h * 4);
	return textureID;
}
*/

/*
value ml_renderbuffer_resize(value orb,value owidth,value oheight) {
	CAMLparam3(orb,owidth,oheight);
	CAMLlocal3(renderInfo,clip,clp);
	double width = Double_val(owidth);
	double height = Double_val(oheight);
	renderbuffer_t *rb = RENDERBUFFER(Field(orb,0));
	value res;
	//fprintf(stderr,"try resize %d:%d from [%f:%f] to [%f:%f]\n",rb->fbid,rb->tid,rb->width,rb->height,width,height);
	if (width == rb->width && height == rb->height) {
		//fprintf(stderr,"resize skip\n");
		res = Val_false;
	}
	else {
		res = Val_true;
		//fprintf(stderr,"resize renderbuffer %d:%d to %f:%f\n",rb->fbid,rb->tid,width,height);
		//GLuint legalWidth = nextPowerOfTwo(ceil(width));
		//GLuint legalHeight = nextPowerOfTwo(ceil(height));
		GLuint legalWidth = nextPOT(ceil(width));
		GLuint legalHeight = nextPOT(ceil(height));
#if defined(IOS) || defined(ANDROID)
		if (legalWidth <= 8) {
			if (legalWidth > legalHeight) legalHeight = legalWidth;
			else 
				if (legalHeight > legalWidth * 2) legalWidth = legalHeight/2; 
				if (legalWidth > 16) legalWidth = 16;
		} else {
			if (legalHeight <= 8) legalHeight = 16 < legalWidth ? 16 : legalWidth;
		};
#endif
		// обновить фсю хуйню 
		rb->vp = (viewport){(GLuint)((legalWidth - width)/2),(GLuint)((legalHeight - height)/2),(GLuint)width,(GLuint)height};
		rb->clp = (clipping){(double)rb->vp.x / legalWidth,(double)rb->vp.y / legalHeight,(width / legalWidth),(height / legalHeight)};
		rb->width = width;
		rb->height = height;
		renderInfo = Field(orb,1);
		//fprintf(stderr,"old %f:%f\n",Double_val(Field(renderInfo,1)),Double_val(Field(renderInfo,2)));
		Store_field(renderInfo,1,owidth);
		Store_field(renderInfo,2,oheight);
		if (!IS_CLIPPING(RENDERBUFFER(Field(orb,0))->clp)) {
			clp = caml_alloc(4 * Double_wosize,Double_array_tag);
			rb = RENDERBUFFER(Field(orb,0));
			Store_double_field(clp,0,rb->clp.x);
			Store_double_field(clp,1,rb->clp.y);
			Store_double_field(clp,2,rb->clp.width);
			Store_double_field(clp,3,rb->clp.height);
			clip = caml_alloc_tuple(1);
			Store_field(clip,0,clp);
		} else clip = Val_unit;
		Store_field(renderInfo,3,clip);
		rb = RENDERBUFFER(Field(orb,0));
		if (legalWidth != rb->realWidth || legalHeight != rb->realHeight) {

			lgGLBindTexture(rb->tid,1);
			glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,legalWidth,legalHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
			rb->realWidth = legalWidth;
			rb->realHeight = legalHeight;

			value mlTextureID;
			TEX(Field(renderInfo,0))->tid = 0;
			total_tex_mem -= TEX(Field(renderInfo,0))->mem;
			caml_free_dependent_memory(TEX(Field(renderInfo,0))->mem);
			int s = legalWidth*legalHeight*4;
			Store_textureID(mlTextureID,rb->tid,"renderbuffer resized",s);
			Store_field(renderInfo,0,mlTextureID);
		};
	};
	checkGLErrors("renderbuffer resize");
	CAMLreturn(res);
}

void ml_renderbuffer_delete(value orb) {
	renderbuffer_t *rb = RENDERBUFFER(orb);
	//fprintf(stderr,"delete renderbuffer: %d\n",rb->fbid);
	glDeleteFramebuffers(1,&rb->fbid);
} */

/* OLD OLD OLD
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



