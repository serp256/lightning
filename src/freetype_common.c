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
#include FT_TRUETYPE_TABLES_H

#ifdef ANDROID
#include "android/lightning_android.h"
#define get_locale lightning_get_locale
#elif IOS
#import "ios/common_ios.h"
#import "ios/CGFontToFontData.h"
#else
#endif

#include "light_common.h"
#include "texture_common.h"

//https://www.microsoft.com/typography/otspec/os2.htm
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
			PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}
}
int texID = 0;
//int fontSize = 18;
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

unsigned char* buf;
char* current_face_name;


void initTextureData () {
		free(_currentPageData);
		_currentPageData= malloc(_currentPageDataSize);
		if (!_currentPageData) {
			caml_failwith(caml_copy_string("Freetype: not enough memory"));
		}
		memset(_currentPageData,0,_currentPageDataSize);
		_currLineHeight = 0;
		_currentPage = 0;
		_currentPageOrigX = 0;
		_currentPageOrigY = 0;
}

int initFreeType() {
    if (_FTInitialized)
    {
        if (FT_Init_FreeType( &_FTlibrary ))
            return 1;
        _FTInitialized = 0;

				glGetIntegerv(GL_MAX_TEXTURE_SIZE,&textureSize);
				adjustForExtend = _letterEdgeExtend / 2;
				_currentPageDataSize = textureSize * textureSize;
				initTextureData ();
    }

    return  _FTInitialized;
}

void loadFace(char* fname, int fontSize) {
	FT_Error error;
	PRINT_DEBUG("loadFace %s %d", fname, fontSize);

	 if (face) {
		free(buf);
		FT_Done_Face(face);
	 }
	PRINT_DEBUG("loadFace: done face");

	long fsize;

	if (*fname == '/') {
		//absolute path
		PRINT_DEBUG ("absolute path");
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

#if (defined IOS )
	CGFontRef cgf = CGFontCreateWithFontName((CFStringRef)@"Helvetica-Bold");

	NSData* data = fontDataForCGFont (cgf);
	PRINT_DEBUG(" len %i", [data length]);
	int length = [data length];
	buf = malloc(length);
	buf = [data bytes];

	error = ( (FT_New_Memory_Face(_FTlibrary, buf, length, 0, &face )));

#else
#if (defined ANDROID)
	resource r;
	if (getResourceFd(fname,&r)) {
		buf = malloc(r.length);
		memset(buf,0, sizeof(buf));
		int64_t i = read(r.fd, buf, r.length);
		int e = errno;
	//	PRINT_DEBUG("fread %lld %s", i, strerror(e));
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
#endif
		}


	//error = ( (FT_New_Memory_Face(_FTlibrary, buf, fsize, 0, &face )));

	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
		caml_failwith(caml_copy_string(getErrorMessage (error)));
	}


	PRINT_DEBUG ("%s: %s", face->family_name,face->style_name);

	current_face_name = fname;

  error = FT_Select_Charmap(face, FT_ENCODING_UNICODE);
	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}

	// set the requested font size
	int fontSizePoints = (int)(64.f * fontSize);
	error= (FT_Set_Char_Size(face, fontSizePoints, fontSizePoints, dpi, dpi));
		if ( error )
		{
			PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
		}
}
void getFontCharmap (char* fname) {
	TT_OS2*  os2;                                     
	os2 =                                                    
		(TT_OS2*)FT_Get_Sfnt_Table( face, FT_SFNT_OS2);   
	PRINT_DEBUG ("0 %s %s", face->family_name, ((os2->ulUnicodeRange1) & (1<<(0)))?"true":"false");
	PRINT_DEBUG ("1 %s %s", face->family_name, ((os2->ulUnicodeRange1) & (1<<(1)))?"true":"false");
	PRINT_DEBUG ("2 %s %s", face->family_name, ((os2->ulUnicodeRange1) & (1<<(2)))?"true":"false");
	PRINT_DEBUG ("cyrrilic %s %s", face->family_name, ((os2->ulUnicodeRange1) & (1<<(9)))?"true":"false");

	PRINT_DEBUG ("arabic %s %s", face->family_name, ((os2->ulUnicodeRange1) & (1<<(13)))?"true":"false");

	PRINT_DEBUG ("cjk %s %s", face->family_name, ((os2->ulUnicodeRange2) & (1<<(27)))?"true":"false");
	PRINT_DEBUG("range1 %lu",((os2->ulUnicodeRange1)));
	PRINT_DEBUG ("range2 %lu", (os2->ulUnicodeRange2));
	PRINT_DEBUG ("randge3: %lu", (os2->ulUnicodeRange3));
	PRINT_DEBUG ("range4: %lu", (os2->ulUnicodeRange4));

	static value* add_font = NULL;
	if (!add_font) add_font = caml_named_value("add_font_ranges");

	value args[5] = { caml_copy_string(fname), caml_copy_int64(os2->ulUnicodeRange1), caml_copy_int64(os2->ulUnicodeRange2), caml_copy_int64(os2->ulUnicodeRange3), caml_copy_int64(os2->ulUnicodeRange4)};
	caml_callbackN(*add_font, 5, args);
}

textureInfo *tInfo;

value ml_freetype_getFont(value ttf, value vsize) { 
	CAMLparam2(ttf, vsize);

	if (initFreeType()) PRINT_DEBUG ("error on freetype init");

	char* fname = String_val(ttf);
	int fontSize = Int_val(vsize);

	PRINT_DEBUG("get FT Font [%s]: %d", fname, fontSize);
	loadFace (fname, fontSize);


	if (!face) {
		caml_failwith(caml_copy_string("Freetype face font is null"));
	}

	current_face_name = fname;
	getFontCharmap(fname);

	FT_Size_Metrics size_info = face->size->metrics;

	FT_Error error;

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
		texID = TEXTURE_ID(textureID);
		mlTexOpt = caml_alloc(1, 0);
		ML_TEXTURE_INFO(mlTex,textureID,(tInfo));
		Store_field( mlTexOpt, 0, mlTex);
		Store_field(mlFont,7,mlTexOpt);
	}
	else {
		Store_field(mlFont,7,Val_int(0));
	}

	CAMLreturn(mlFont);
}
value ml_freetype_checkChar (value vtext, value vface, value vsize) {
	PRINT_DEBUG("ml_freetype_checkChar");
	CAMLparam3(vtext,vface,vsize);

	int code = Int_val(vtext);
	int fontSize = Int_val(vsize);

	FT_Error error;

	char* cface = String_val(vface);

	PRINT_DEBUG("check face [%s], current [%s]", cface, current_face_name);


	if (current_face_name && strlen(cface) > 0 && strcmp(current_face_name, cface) != 0) { 
		loadFace (cface, fontSize);
	}

	unsigned int glyph_index = 	FT_Get_Char_Index(face, code);
	if (glyph_index == 0 ) {
		PRINT_DEBUG("not found char %d in %s", code, face->family_name);
		CAMLreturn(caml_copy_string(""));
	} else {
		PRINT_DEBUG("found char %d in %s", code, face->family_name);
		CAMLreturn(caml_copy_string(face->family_name));
	}
}

value ml_freetype_getChar(value vtext, value vface, value vsize) {
	PRINT_DEBUG("ml_freetype_getChar");
	CAMLparam3(vtext,vface,vsize);
	CAMLlocal2(mlChar,mlCharOpt);

	int code = Int_val(vtext);

	int fontSize = Int_val(vsize);
	int fontSizePoints = (int)(64.f * fontSize);

	FT_Error error;
	PRINT_DEBUG("1");


	char* cface = String_val(vface);

	if (current_face_name && strlen(cface) > 0 && strcmp(current_face_name, cface) != 0) { 
		loadFace (cface, fontSize);
	}

	fontLetterDefinition tempDef;

	unsigned int glyph_index = 	FT_Get_Char_Index(face, code);
	FT_Size_Metrics size_info = face->size->metrics;
	if (face->size->metrics.x_ppem != fontSizePoints) {
		error= (FT_Set_Char_Size(face, fontSizePoints, fontSizePoints, dpi, dpi));
		print_error(error);
	}

	int _fontAscender = face->size->metrics.ascender >> 6;
	int _lineHeight = face->size->metrics.height >> 6;
	 error = FT_Load_Glyph(face,glyph_index, FT_LOAD_RENDER | FT_LOAD_NO_AUTOHINT);
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
			if (_currentPageOrigY + _lineHeight >= textureSize){
				PRINT_DEBUG ("No more space in texture");
			}

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
	initTextureData();
	CAMLreturn(Val_unit);
}
