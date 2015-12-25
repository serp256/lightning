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

const char* getErrorMessage(FT_Error err) {
	    #undef __FTERRORS_H__
	    #define FT_ERRORDEF( e, v, s )  case e: return s;
	    #define FT_ERROR_START_LIST     switch (err) {
				    #define FT_ERROR_END_LIST       }
	    #include FT_ERRORS_H
	    return "(Unknown error)";
}
int textureSize= 512;
FT_Library _FTlibrary;
FT_Face face;
int _FTInitialized = 1;

int initFreeType() {
    if (_FTInitialized)
    {
        if (FT_Init_FreeType( &_FTlibrary ))
            return 1;
        _FTInitialized = 0;
    }

    return  _FTInitialized;
}

value ml_freetype_getFont(value ttf) { 
	CAMLparam1(ttf);

	if (initFreeType()) PRINT_DEBUG ("error on freetype init");

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
	int fontSize = 18;
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
	
	CAMLlocal1(mlFont);
	mlFont = caml_alloc_tuple(7);
	Store_field(mlFont,0,caml_copy_string(face->family_name));
	Store_field(mlFont,1,caml_copy_string(face->style_name));
	Store_field(mlFont,2,caml_copy_double(1.));
	Store_field(mlFont,3,caml_copy_double(size_info.ascender>>6));
	Store_field(mlFont,4,caml_copy_double(- (size_info.descender>>6)));
	Store_field(mlFont,5,caml_copy_double(size_info.height>>6));
	Store_field(mlFont,6,caml_copy_double(face->glyph->metrics.horiAdvance>>6));
	CAMLreturn(mlFont);
}

void print_error(FT_Error error) {
	if (error) {
			PRINT_DEBUG("FT error: %s", caml_copy_string(getErrorMessage (error)));
	}
}

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


value ml_freetype_getTLF(value vtext) {
	CAMLparam1(vtext);

	char* text = String_val(vtext);
	char code = *text;
	PRINT_DEBUG ( "%s, %c", text, code);

	if (face==NULL) {
		caml_failwith("no face initialized");
	}

	FT_Error error;
	unsigned int totalWidth = 0; 
	unsigned int totalHeight = 0;
	unsigned char* ret = malloc(textureSize*textureSize);
	int dataLen = 0;
	while (text!=NULL && *text != '\0') {

		PRINT_DEBUG("%c", *text);

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
		int bufferSize = w * h;

/*
		auto& metrics = _fontRef->glyph->metrics;
        outRect.origin.x = metrics.horiBearingX >> 6;
        outRect.origin.y = -(metrics.horiBearingY >> 6);
        outRect.size.width = (metrics.width >> 6);
        outRect.size.height = (metrics.height >> 6);

        xAdvance = (static_cast<int>(_fontRef->glyph->metrics.horiAdvance >> 6));

        outWidth  = _fontRef->glyph->bitmap.width;
        outHeight = _fontRef->glyph->bitmap.rows;
        ret = _fontRef->glyph->bitmap.buffer;
*/







    
		PRINT_DEBUG ("w, h %d %d", w, h);
		PRINT_DEBUG ("buffer %d, dta %d", bufferSize, dataLen);
		//renderCharAt(ret,totalWidth, 0, buffer, w,h);
		memcpy(ret+dataLen,buffer,w*h);
		dataLen += bufferSize;

		totalWidth += w;
		++text;
		
	}
	PRINT_DEBUG("loaded PNG image: %d:%d",totalWidth,totalHeight);

	unsigned char* bret = malloc(dataLen);
	memcpy(bret,ret,dataLen);
	textureInfo *tInfo= (textureInfo*)malloc(sizeof(textureInfo));

	tInfo->format = LTextureFormatAlpha;
	tInfo->width = totalWidth;
	tInfo->realWidth = totalWidth;
	tInfo->height = totalHeight;
	tInfo->realHeight =  totalHeight;
	tInfo->numMipmaps = 0;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = 1;
	tInfo->scale = 1.;
	tInfo->dataLen = dataLen;
	tInfo->imgData = bret;

	PRINT_DEBUG ("ok");
	CAMLlocal2(mlTex, textureID);
	textureID = createGLTexture(1,tInfo,1);

	ML_TEXTURE_INFO(mlTex,textureID,(tInfo));
	PRINT_DEBUG("Field(mlTex,0) %d", Int_val(Field(mlTex,0)));

	CAMLreturn(mlTex);

}

