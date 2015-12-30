#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include <caml/alloc.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>


#include <ft2build.h>
#include FT_FREETYPE_H

#ifdef ANDROID
#include "android/lightning_android.h"
#define get_locale lightning_get_locale
#elif IOS
#import "ios/common_ios.h"
#else
#endif

#include "light_common.h"
#include "texture_common.h"

typedef struct {
	char *family;
	char *style;
	double scale;
	double ascender;
	double descender;
	double lineHeight;
	double space;
} fontInfo;

typedef struct {
	float x;
	float y;
	float width;
	float height;
	float offsetX;
	float offsetY;
	int textureID;
	int validDefinition;
	int xAdvance;
} fontLetterDefinition;

const char* getErrorMessage(FT_Error err) {
	    #undef __FTERRORS_H__
	    #define FT_ERRORDEF( e, v, s )  case e: return s;
	    #define FT_ERROR_START_LIST     switch (err) {
				    #define FT_ERROR_END_LIST       }
	    #include FT_ERRORS_H
	    return "(Unknown error )";
}


void print_error(FT_Error error) {
	if (error) {
			//PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}
}
int texID = 0;
int fontSize = 18;
int textureSize= 2048;
void renderCharAt(unsigned char *dest,int posX, int posY, unsigned char* bitmap,long bitmapWidth,long bitmapHeight)
{
    int iX = posX;
    int iY = posY;
		{
			long y;
        for (y = 0; y < bitmapHeight; ++y)
        {
            long bitmap_y = y * bitmapWidth;

						int x;
            for (x = 0; x < bitmapWidth; ++x)
            {
                unsigned char cTemp = bitmap[bitmap_y + x];

                // the final pixel
                dest[(iX + ( iY * textureSize ) )] = cTemp;

                iX += 1;
            }

            iX  = posX;
            iY += 1;
        }
    }
}

FT_Library _FTlibrary;
FT_Face face;
int _FTInitialized = 1;

int dpi = 72;
int _currLineHeight = 0;
int _currentPage = 0;
int _currentPageOrigX = 0;
int _currentPageOrigY = 0;
int _letterEdgeExtend = 0;
int adjustForExtend;
unsigned char* _currentPageData;
int _currentPageDataSize;

int initFreeType() {
    if (_FTInitialized)
    {
        if (FT_Init_FreeType( &_FTlibrary ))
            return 1;
        _FTInitialized = 0;
    }

    return  _FTInitialized;
}
textureInfo *tInfo;
value ml_freetype_getFont(value ttf, value vsize) { 
	CAMLparam2(ttf, vsize);

	PRINT_DEBUG("get FT Font");
	if (initFreeType()) PRINT_DEBUG ("error on freetype init");
	adjustForExtend = _letterEdgeExtend / 2;

	_currentPageDataSize = textureSize * textureSize;
	_currentPageData= malloc(_currentPageDataSize);
	memset(_currentPageData,0,_currentPageDataSize);

	//int error = FT_New_Face(_FTlibrary, String_val(ttf), 0, &face);

	FT_Error error;
	/*
	if (getResourceFd(String_val(ttf),&r)) {
		PRINT_DEBUG("getResourceFd return true");
		PRINT_DEBUG("%lld", r.length);

		FILE *fp = fdopen(r.fd, "rb");

		fseek(fp,0,SEEK_END);
		fseek(fp,0,SEEK_SET);
		unsigned char* buf = malloc(r.length);
		if (read(r.fd, buf, r.length) != r.length)  {
			PRINT_DEBUG("fail read");
		}
		*/
		/*
		int64_t i = fread(buf,sizeof(unsigned char), r.length,fp);
		PRINT_DEBUG("ipizda %lld", i);
		*/
		char* fname = String_val(ttf);
		unsigned char* buf;
		long fsize;
		if (*fname == '/') {
			//absolute path
			PRINT_DEBUG ("absilute path %s", fname);
			FILE *f = fopen(fname, "rb");

			fseek(f,0,SEEK_END);
			fsize = ftell(f);
			fseek(f,0,SEEK_SET);
			buf = malloc(fsize);
			memset(buf,0, sizeof(buf));
			fread(buf, fsize,1,f);
			error = ( (FT_New_Memory_Face(_FTlibrary, buf, fsize, 0, &face )));
			fclose(f);
		} else {
#if (defined IOS || defined ANDROID)
	resource r;
	if (getResourceFd(fname,&r)) {
		buf = malloc(r.length);
		memset(buf,0, sizeof(buf));
		int64_t i = read(r.fd, buf, r.length);
		int e = errno;
		PRINT_DEBUG("fread %lld %s", i, strerror(e));
		error = ( (FT_New_Memory_Face(_FTlibrary, buf, r.length, 0, &face )));
	}

#else
		char* dir = "Resources/";
		PRINT_DEBUG ("fdir %s", dir);
		PRINT_DEBUG ("fname %s", fname);

		size_t len1 = strlen(fname);
		size_t len2 = strlen(dir);
		char *result = malloc(len1+len2+1);

		memcpy(result, dir, len2);
		memcpy(result+len2, fname, len1+1);
		PRINT_DEBUG ("fpath %s", result);


		FILE *f = fopen(result, "rb");

		fseek(f,0,SEEK_END);
	  fsize = ftell(f);
		fseek(f,0,SEEK_SET);
		buf = malloc(fsize);
		memset(buf,0, sizeof(buf));
		fread(buf, fsize,1,f);
		error = ( (FT_New_Memory_Face(_FTlibrary, buf, fsize, 0, &face )));
		fclose(f);
#endif
		}

	//error = ( (FT_New_Memory_Face(_FTlibrary, buf, fsize, 0, &face )));

	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
		caml_failwith(caml_copy_string(getErrorMessage (error)));
	}


	PRINT_DEBUG ("%s: %s", face->family_name,face->style_name);

  error = FT_Select_Charmap(face, FT_ENCODING_UNICODE);
	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}

	// set the requested font size
	fontSize = Int_val(vsize);
	int fontSizePoints = (int)(64.f * fontSize);
	error= (FT_Set_Char_Size(face, fontSizePoints, fontSizePoints, dpi, dpi));
		if ( error )
		{
			PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
		}

	FT_Size_Metrics size_info = face->size->metrics;

	error = FT_Load_Glyph(face,FT_Get_Char_Index(face, ' '), FT_LOAD_DEFAULT);
	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}
	
	CAMLlocal4(mlFont,mlTex,textureID, mlTexOpt);
	mlFont = caml_alloc_tuple(8);
	Store_field(mlFont,0,caml_copy_string(face->family_name));
	Store_field(mlFont,1,caml_copy_string(face->style_name));
	Store_field(mlFont,2,caml_copy_double(1.));
	Store_field(mlFont,3,caml_copy_double(size_info.ascender>>6));
	Store_field(mlFont,4,caml_copy_double(- (size_info.descender>>6)));
	Store_field(mlFont,5,caml_copy_double(size_info.height>>6));
	Store_field(mlFont,6,caml_copy_double(face->glyph->metrics.horiAdvance>>6));
	


	PRINT_DEBUG ("ok");
	if (texID == 0) {
		tInfo= (textureInfo*)malloc(sizeof(textureInfo));

		tInfo->format = LTextureFormatAlpha;
		tInfo->width = textureSize;
		tInfo->realWidth = textureSize;
		tInfo->height = textureSize;
		tInfo->realHeight =  textureSize;
		tInfo->numMipmaps = 0;
		tInfo->generateMipmaps = 0;
		tInfo->premultipliedAlpha = 1;
		tInfo->scale = 1.;
		tInfo->dataLen = _currentPageDataSize;
		tInfo->imgData = _currentPageData;

		textureID = createGLTexture(1,tInfo,1);
		PRINT_DEBUG("+++++++++++++++tid %d", TEXTURE_ID(textureID));
		texID = TEXTURE_ID(textureID);
		mlTexOpt = caml_alloc(1, 0);
		ML_TEXTURE_INFO(mlTex,textureID,(tInfo));
		PRINT_DEBUG("Field(mlTex,0) %d", Int_val(Field(mlTex,0)));
		Store_field( mlTexOpt, 0, mlTex);
		Store_field(mlFont,7,mlTexOpt);
	}
	else {
		Store_field(mlFont,7,Val_int(0));
	}
	

	CAMLreturn(mlFont);
}

value ml_freetype_getChar(value vtext, value vsize) {
	CAMLparam2(vtext,vsize);
	CAMLlocal2(mlChar,mlCharOpt);

	int code = Int_val(vtext);

	fontSize = Int_val(vsize);
	int fontSizePoints = (int)(64.f * fontSize);

	FT_Error error;
	FT_Size_Metrics size_info = face->size->metrics;
	if (face->size->metrics.x_ppem != fontSizePoints) {
		error= (FT_Set_Char_Size(face, fontSizePoints, fontSizePoints, dpi, dpi));
		print_error(error);
	}


	if (face==NULL) {
		caml_failwith("no face initialized");
	}


	fontLetterDefinition tempDef;
	int _fontAscender = face->size->metrics.ascender >> 6;
	int _lineHeight = face->size->metrics.height >> 6;

	//float startY = _currentPageOrigY;

		PRINT_DEBUG(" %c: %x", code, code);

		error =(FT_Load_Char(face, code, FT_LOAD_RENDER | FT_LOAD_NO_AUTOHINT));

		if (face->glyph->format == FT_GLYPH_FORMAT_BITMAP) {
			PRINT_DEBUG("is bitmap");
		}
		else {
			PRINT_DEBUG("not bitmap");
			error = FT_Render_Glyph( face->glyph, FT_RENDER_MODE_NORMAL);
			print_error (error);
		}

		print_error(error);

		
		unsigned char* buffer = face->glyph->bitmap.buffer;

		int w = face->glyph->bitmap.width;
		int h = face->glyph->bitmap.rows;
		 
		if (buffer && w > 0 && h > 0) {
			FT_Glyph_Metrics metrics = face->glyph->metrics;
			tempDef.validDefinition = 0;
			tempDef.width = (metrics.width >> 6) + _letterEdgeExtend;
			tempDef.height = (metrics.height >> 6) + _letterEdgeExtend;
			tempDef.offsetX = (metrics.horiBearingX >> 6) + adjustForExtend;
			tempDef.offsetY = _fontAscender -(metrics.horiBearingY >> 6) - adjustForExtend;
			tempDef.xAdvance = face->glyph->metrics.horiAdvance >> 6;

		if (h > _currLineHeight)
		{
			_currLineHeight = h + _letterEdgeExtend + 1;
		}

		if (_currentPageOrigX + tempDef.width > textureSize)
		{
			_currentPageOrigY += _currLineHeight;
			_currLineHeight = 0;
			_currentPageOrigX = 0;
		}
		renderCharAt(_currentPageData, _currentPageOrigX + adjustForExtend, _currentPageOrigY + adjustForExtend, buffer, w, h);

		tempDef.x = _currentPageOrigX;
		tempDef.y = _currentPageOrigY;
		tempDef.textureID = _currentPage;
		_currentPageOrigX += tempDef.width + 1;
		}
		else{
			if (tempDef.xAdvance)
				tempDef.validDefinition = 0;
			else
				tempDef.validDefinition = 1;

			tempDef.width = 0;
			tempDef.height = 0;
			tempDef.x = 0;
			tempDef.y = 0;
			tempDef.offsetX = 0;
			tempDef.offsetY = 0;
			tempDef.textureID = 0;
			_currentPageOrigX += 1;
		}

		if (tempDef.validDefinition==0) {
			PRINT_DEBUG ("create char");
			mlChar = caml_alloc_tuple(8);

			Store_field(mlChar,0, Val_int(code));
			Store_field(mlChar,1,caml_copy_double(tempDef.x));
			Store_field(mlChar,2,caml_copy_double(tempDef.y));
			Store_field(mlChar,3,caml_copy_double(tempDef.width));
			Store_field(mlChar,4,caml_copy_double(tempDef.height));
			Store_field(mlChar,5,caml_copy_double(tempDef.offsetX));
			Store_field(mlChar,6,caml_copy_double(tempDef.offsetY));
			Store_field(mlChar,7,caml_copy_double(tempDef.xAdvance));

			/*
			glBindTexture(GL_TEXTURE_2D, texID);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, textureSize, textureSize, 0, GL_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);
			*/

			mlCharOpt = caml_alloc(1, 0);
			Store_field( mlCharOpt, 0, mlChar );
			CAMLreturn( mlCharOpt);

		}
		else {
			CAMLreturn(Val_int(0));
		}
}

value ml_freetype_bindTexture(value unit) {
	CAMLparam0();

	PRINT_DEBUG("FT bindTexture");
			glBindTexture(GL_TEXTURE_2D, texID);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, textureSize, textureSize, 0, GL_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);
	CAMLreturn(Val_unit);
}
