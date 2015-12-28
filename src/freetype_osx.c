#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <caml/alloc.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>


#include <ft2build.h>
#include FT_FREETYPE_H
/*#include <freetype/ftglyph.h>
#include <freetype/ftstroke.h>
#include <freetype/ftbitmap.h>
#include <freetype/ftbbox.h>
#include <freetype/freetype.h>
*/

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
	    return "(Unknown error)";
}

void print_error(FT_Error error) {
	if (error) {
			PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}
}
int fontSize = 18;
int textureSize= 2048;
void renderCharAt(unsigned char *dest,int posX, int posY, unsigned char* bitmap,long bitmapWidth,long bitmapHeight)
{
    int iX = posX;
    int iY = posY;
		{
        for (long y = 0; y < bitmapHeight; ++y)
        {
            long bitmap_y = y * bitmapWidth;

            for (int x = 0; x < bitmapWidth; ++x)
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
value ml_freetype_getFont(value ttf) { 
	CAMLparam1(ttf);

	if (initFreeType()) PRINT_DEBUG ("error on freetype init");
	adjustForExtend = _letterEdgeExtend / 2;

	_currentPageDataSize = textureSize * textureSize;
	_currentPageData= malloc(_currentPageDataSize);
	memset(_currentPageData,0,_currentPageDataSize);

	int error = FT_New_Face(_FTlibrary, String_val(ttf), 0, &face);

	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
		caml_failwith(caml_copy_string(getErrorMessage (error)));
	}

  error = FT_Select_Charmap(face, FT_ENCODING_UNICODE);
	if ( error )
	{
		PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}

	// set the requested font size
	int dpi = 72;
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
	
	CAMLlocal3(mlFont,mlTex,textureID);
	mlFont = caml_alloc_tuple(8);
	Store_field(mlFont,0,caml_copy_string(face->family_name));
	Store_field(mlFont,1,caml_copy_string(face->style_name));
	Store_field(mlFont,2,caml_copy_double(1.));
	Store_field(mlFont,3,caml_copy_double(size_info.ascender>>6));
	Store_field(mlFont,4,caml_copy_double(- (size_info.descender>>6)));
	Store_field(mlFont,5,caml_copy_double(size_info.height>>6));
	Store_field(mlFont,6,caml_copy_double(face->glyph->metrics.horiAdvance>>6));

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

	PRINT_DEBUG ("ok");
	textureID = createGLTexture(1,tInfo,1);

	PRINT_DEBUG("TEXTURE ID %d", textureID);
	ML_TEXTURE_INFO(mlTex,textureID,(tInfo));
	PRINT_DEBUG("Field(mlTex,0) %d", Int_val(Field(mlTex,0)));
	Store_field(mlFont,7,mlTex);



	CAMLreturn(mlFont);
}

/*
value ml_freetype_getChar(value vcode) {
	CAMLparam1(vcode);


	if (face==NULL) {
		caml_failwith("no face initialized");
	}

	FT_Error error;
	int code = Int_val(vcode);
	PRINT_DEBUG("get char %d:%c", code, code);
	error =(FT_Load_Char(face, code, FT_LOAD_RENDER | FT_LOAD_NO_AUTOHINT));
	print_error(error);

	CAMLlocal1(mlBc);
	mlBc = caml_alloc_tuple(4);
	Store_field(mlBc,0,vcode);
	Store_field(mlBc,1,caml_copy_double(face->glyph->bitmap_left));
	Store_field(mlBc,2,caml_copy_double(face->glyph->bitmap_top));
	Store_field(mlBc,3,caml_copy_double(face->glyph->metrics.horiAdvance >> 6));

	CAMLreturn(mlBc);

}
*/


value ml_freetype_getChar(value vtext) {
	CAMLparam1(vtext);
	CAMLlocal2(mlChar,mlCharOpt);

	PRINT_DEBUG("GETCHAR");
	int code = Int_val(vtext);
	PRINT_DEBUG("GETCHAR %d", code);


	if (face==NULL) {
		caml_failwith("no face initialized");
	}

	FT_Error error;

	fontLetterDefinition tempDef;
	int _fontAscender = face->size->metrics.ascender >> 6;
	int _lineHeight = face->size->metrics.height >> 6;

	float startY = _currentPageOrigY;

		PRINT_DEBUG("%c", code);

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

			glBindTexture(GL_TEXTURE_2D, 1);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, textureSize, textureSize, 0, GL_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);

			mlCharOpt = caml_alloc(1, 0);
			Store_field( mlCharOpt, 0, mlChar );
			CAMLreturn( mlCharOpt);

		}
		else {
			CAMLreturn(Val_int(0));
		}




}
