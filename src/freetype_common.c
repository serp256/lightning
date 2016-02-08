#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include <caml/alloc.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>


/*
#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import <caml/threads.h>

#import "light_common.h"
#import "mlwrapper_ios.h"
#import "LightViewController.h"
*/





#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_STROKER_H
#include FT_TRUETYPE_TABLES_H

#ifdef ANDROID
#include "android/lightning_android.h"
#define get_locale lightning_get_locale
#elif IOS
#import "ios/common_ios.h"
#import "ios/CGFontToFontData.h"
#import <UIKit/UIKit.h> 
#else
#endif

#include "light_common.h"
#include "texture_common.h"

#define MIN(a,b) a < b ? a : b
#define MAX(a,b) a > b ? a : b
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
			PRINT_DEBUG("FT error: %s", getErrorMessage (error));
	}
}
int texID = 0;
//int fontSize = 18;
int textureSize= 0;
int textureIsOver = 0;
double _outline;
void renderCharAt(unsigned char *dest,int posX, int posY, unsigned char* bitmap,long bitmapWidth,long bitmapHeight)
{
    int iX = posX;
    int iY = posY;
		long y;
		int x;

		if(_outline > 0) {
				unsigned char tempChar;
				PRINT_DEBUG("copy");
				for (y = 0; y < bitmapHeight; ++y)
				{
						long bitmap_y = y * bitmapWidth;

						for (x = 0; x < bitmapWidth; ++x)
						{
								tempChar = bitmap[(bitmap_y + x) * 2];
								dest[(iX + ( iY * textureSize) ) * 2] = tempChar;
								tempChar = bitmap[(bitmap_y + x) * 2 + 1];
								dest[(iX + ( iY * textureSize) ) * 2 + 1] = tempChar;

								iX += 1;
						}

						iX  = posX;
						iY += 1;
				}
				PRINT_DEBUG("free");
				free(bitmap);
				PRINT_DEBUG("freeed");
		}
		else {
			for (y = 0; y < bitmapHeight; ++y)
			{
					long bitmap_y = y * bitmapWidth;

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
FT_Stroker stroker;

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
double scale = 1.;

value ml_freetype_setStroke(value vstroke) {
	CAMLparam1(vstroke);
	_outline = (double) (Int_val(vstroke) / 100.0);
	PRINT_DEBUG("outline %f", _outline);
	CAMLreturn(Val_unit);
}

value ml_freetype_setScale(value vscale) {
	CAMLparam1(vscale);
	scale = Double_val(vscale);
	CAMLreturn(Val_unit);
}

value ml_freetype_setTextureSize(value vsize) {
	CAMLparam1(vsize);
	textureSize = Int_val(vsize);
	CAMLreturn(Val_unit);
}


void initTextureData () {
		PRINT_DEBUG("1");
		free(_currentPageData);
		textureIsOver = 0;
		PRINT_DEBUG("1 %i",_currentPageDataSize);
		_currentPageData= malloc(_currentPageDataSize);
		PRINT_DEBUG("1");
		if (!_currentPageData) {
				caml_failwith("Freetype: not enough memory");
		}
		memset(_currentPageData,0,_currentPageDataSize);
		_currLineHeight = 0;
		_currentPage = 0;
		_currentPageOrigX = 0;
		_currentPageOrigY = 0;
		PRINT_DEBUG("3");
}

int initFreeType() {
    if (_FTInitialized)
    {
        if (FT_Init_FreeType( &_FTlibrary ))
            return 1;
        _FTInitialized = 0;

				if (textureSize==0) {
					glGetIntegerv(GL_MAX_TEXTURE_SIZE,&textureSize);
				}
				PRINT_DEBUG("textureSize %d", textureSize);

				adjustForExtend = _letterEdgeExtend / 2;
				_currentPageDataSize = textureSize * textureSize;//textureSize * textureSize;
				_currentPageDataSize = _outline > 0 ?  _currentPageDataSize* 2 : _currentPageDataSize; 
				initTextureData ();
    }

    return  _FTInitialized;
}

void loadFace(char* fname, int fSize) {
	FT_Error error;
	PRINT_DEBUG("loadFace %s %d", fname, fSize);

	double dfsize = (double)(scale * fSize);
	int fontSize =  (int)(dfsize + 0.45);
	 if (face) {
		FT_Done_Face(face);
		free(buf);
	 }
	PRINT_DEBUG("loadFace: done face");

	double outlineSize = (double)(dfsize * _outline);
	if (_outline > 0) {
		FT_Stroker_New(_FTlibrary, &stroker);
		FT_Stroker_Set(stroker,
				(int)(outlineSize * 64),
				FT_STROKER_LINECAP_ROUND,
				FT_STROKER_LINEJOIN_ROUND,
				0);
	}

	long fsize;

	if (*fname == '/') {
		//absolute path
		PRINT_DEBUG ("absolute path");
		FILE *f = fopen(fname, "rb");

		fseek(f,0,SEEK_END);
		fsize = ftell(f);
		fseek(f,0,SEEK_SET);
		buf = malloc(fsize);
		memset(buf,0, fsize);
		fread(buf, fsize,1,f);
		error = ( (FT_New_Memory_Face(_FTlibrary, buf, fsize, 0, &face )));
		fclose(f);
	} else {

#if (defined IOS )

  NSString *fontName= [NSString stringWithCString:fname encoding:NSUTF8StringEncoding];
	CGFontRef cgf = CGFontCreateWithFontName((CFStringRef)fontName);

	NSData* data =(NSData*) fontDataForCGFont (cgf);
	PRINT_DEBUG(" len %s %i", fname, [data length]);
	int length = [data length];
	buf = malloc(length);
	memset(buf,0,length);
	memcpy(buf,[data bytes],length);


	fname = [fontName UTF8String];
	error = ( (FT_New_Memory_Face(_FTlibrary, buf, length, 0, &face )));

#else
#if (defined ANDROID)
	resource r;
	if (getResourceFd(fname,&r)) {
		buf = malloc(r.length);
		memset(buf,0, r.length);
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
#endif
		}


	//error = ( (FT_New_Memory_Face(_FTlibrary, buf, fsize, 0, &face )));

	if ( error )
	{
		PRINT_DEBUG("FT error: %s", getErrorMessage (error));
		caml_failwith(getErrorMessage (error));
	}


	PRINT_DEBUG ("%s: %s", face->family_name,face->style_name);

	current_face_name = fname;

  error = FT_Select_Charmap(face, FT_ENCODING_UNICODE);
	if ( error )
	{
		PRINT_DEBUG("FT error: %s", getErrorMessage (error));
	}

	// set the requested font size
	int fontSizePoints = (int)(64.f * fontSize);
	error= (FT_Set_Char_Size(face, fontSizePoints, fontSizePoints, dpi, dpi));
		if ( error )
		{
			PRINT_DEBUG("FT error: %s", getErrorMessage (error));
		}
}
void getFontCharmap (char* fname) {
	TT_OS2*  os2;                                     
	os2 = (TT_OS2*)FT_Get_Sfnt_Table( face, FT_SFNT_OS2);   
	/*
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
	*/

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
		caml_failwith("Freetype face font is null");
	}
	PRINT_DEBUG("FACE %p", face);

	//current_face_name = fname;
	getFontCharmap(current_face_name);









	FT_Size_Metrics size_info = face->size->metrics;

	PRINT_DEBUG("FACE %p", face);

	FT_Error error;

	error = FT_Load_Glyph(face,FT_Get_Char_Index(face, ' '), FT_LOAD_DEFAULT);
	if ( error )
	{
		PRINT_DEBUG("FT error: %s", getErrorMessage (error));
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

		tInfo->format = _outline > 0 ?  LTextureLuminanceAlpha :LTextureFormatAlpha;
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
	CAMLparam3(vtext,vface,vsize);
	PRINT_DEBUG("ml_freetype_checkChar %p %s", face, face->family_name);

	
	if (textureIsOver == 1) {
		CAMLreturn(caml_copy_string(face->family_name));
	}
	int code = Int_val(vtext);
	int fontSize = Int_val(vsize);

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

value ml_freetype_bindTexture(value unit) {
	CAMLparam0();

	PRINT_DEBUG("FT bindTexture");
	glBindTexture(GL_TEXTURE_2D, texID);

	if (_outline > 0) {
		PRINT_DEBUG("outline");
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, textureSize, textureSize, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);
	}
	else {
		glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, textureSize, textureSize, 0, GL_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);
	}
	PRINT_DEBUG("end");
	//initTextureData();
	CAMLreturn(Val_unit);
}


value ml_freetype_getChar(value vtext, value vface, value vsize) {
	PRINT_DEBUG("ml_freetype_getChar");
	CAMLparam3(vtext,vface,vsize);
	CAMLlocal2(mlChar,mlCharOpt);

	if (textureIsOver == 1) {
		PRINT_DEBUG ("No more space");
		CAMLreturn(Val_int(0));
	}
	int code = Int_val(vtext);
	int invalidChar = 0;

	double dfsize = (double)(scale * Int_val(vsize));
	int fontSize =  (int)(dfsize + 0.45);
	int fontSizePoints = (int)(64.f * fontSize);
	double outlineSize = (double)(dfsize * _outline);

	FT_Error error;

	char* cface = String_val(vface);

	PRINT_DEBUG ("cur %s, load %s", current_face_name, cface);
	if (current_face_name && strlen(cface) > 0 && strcmp(current_face_name, cface) != 0) { 
		loadFace (cface, fontSize);
	}

	fontLetterDefinition tempDef;

	unsigned int glyph_index = 	FT_Get_Char_Index(face, code);
	if (face->size->metrics.x_ppem != fontSizePoints) {
		error= (FT_Set_Char_Size(face, fontSizePoints, fontSizePoints, dpi, dpi));
		print_error(error);
	}

	int _fontAscender = face->size->metrics.ascender >> 6;
	int _lineHeight = face->size->metrics.height >> 6;
	PRINT_DEBUG("index %d",glyph_index);
	 error = FT_Load_Glyph(face,glyph_index, FT_LOAD_RENDER | FT_LOAD_NO_AUTOHINT);
	 print_error(error);
		
		unsigned char* buffer = face->glyph->bitmap.buffer;

		unsigned int outWidth = face->glyph->bitmap.width;
		unsigned int outHeight = face->glyph->bitmap.rows;


		FT_Glyph_Metrics metrics = face->glyph->metrics;

		if (buffer && outWidth > 0 && outHeight > 0) {
			PRINT_DEBUG("buffer: %u %u", outWidth, outHeight);

			tempDef.xAdvance = face->glyph->metrics.horiAdvance >> 6;

			if (_outline > 0) {
				int bsize = outWidth * outHeight;
				PRINT_DEBUG ("copy");
				unsigned char* copyBitmap = malloc(bsize);
				memset(copyBitmap, 0, bsize);
				memcpy(copyBitmap, buffer, bsize);
				PRINT_DEBUG ("copied");

				FT_BBox bbox;
				unsigned char* outlineBitmap = NULL;

				if (FT_Load_Char(face, code, FT_LOAD_NO_BITMAP) == 0) {
					if (face->glyph->format == FT_GLYPH_FORMAT_OUTLINE) {
						FT_Glyph glyph;
						if (FT_Get_Glyph(face->glyph, &glyph) == 0) {

							PRINT_DEBUG("stroke");
							error = FT_Glyph_StrokeBorder(&glyph, stroker, 0, 1);
							print_error(error);

							if (glyph->format == FT_GLYPH_FORMAT_OUTLINE) {
								FT_Outline* ft_outline = &(((FT_OutlineGlyph)glyph)->outline);
								FT_Glyph_Get_CBox(glyph,FT_GLYPH_BBOX_GRIDFIT,&bbox);
								long width = (bbox.xMax - bbox.xMin)>>6;
								long rows = (bbox.yMax - bbox.yMin)>>6;

								FT_Bitmap bmp;
							PRINT_DEBUG("bitmap");
								bmp.buffer = malloc(width * rows);
								memset(bmp.buffer, 0, width * rows);
								bmp.width = (int)width;
								bmp.rows = (int)rows;
								bmp.pitch = (int)width;
								bmp.pixel_mode = FT_PIXEL_MODE_GRAY;
								bmp.num_grays = 256;

								FT_Raster_Params params;
								memset(&params, 0, sizeof (params));
								params.source = ft_outline;
								params.target = &bmp;
								params.flags = FT_RASTER_FLAG_AA;
								FT_Outline_Translate(ft_outline,-bbox.xMin,-bbox.yMin);
								FT_Outline_Render(_FTlibrary, ft_outline, &params);

								outlineBitmap  = bmp.buffer;
							}
							FT_Done_Glyph(glyph);
						}
					}
				}

				if (outlineBitmap) {
					PRINT_DEBUG("outlineBitmap");
					

					long glyphMinX = (metrics.horiBearingX >> 6);
					long glyphMaxX =  (metrics.horiBearingX >> 6) + outWidth;
					long glyphMinY = -outHeight + (metrics.horiBearingY >> 6) ;
					long glyphMaxY = (metrics.horiBearingY >> 6);


					long outlineMinX = bbox.xMin >> 6;
					long outlineMaxX = bbox.xMax >> 6;
					long outlineMinY = bbox.yMin >> 6;
					long outlineMaxY = bbox.yMax >> 6;
					long outlineWidth = outlineMaxX - outlineMinX;
					long outlineHeight = outlineMaxY - outlineMinY;

					long blendImageMinX = (long)(MIN(outlineMinX, glyphMinX));
					long blendImageMaxY = (long)(MAX(outlineMaxY, glyphMaxY));
					long blendWidth = (long)(MAX(outlineMaxX, glyphMaxX)) - (blendImageMinX);
					long blendHeight = blendImageMaxY - (long)(MIN(outlineMinY, glyphMinY));

					long index, index2;
					unsigned char* blendImage = malloc(blendWidth * blendHeight * 2);
					PRINT_DEBUG("blend");
					memset(blendImage, 0, blendWidth * blendHeight * 2);
					PRINT_DEBUG("blend copied");

					long px = outlineMinX - blendImageMinX;
					long py = blendImageMaxY - outlineMaxY;
					int x;
					for (x = 0; x < outlineWidth; ++x) {
						int y; 
						for (y = 0; y < outlineHeight; ++y) {
							index = px + x + ((py + y) * blendWidth);
							index2 = x + (y * outlineWidth);
							blendImage[2 * index] = outlineBitmap[index2];
						}
					}
					px = glyphMinX - blendImageMinX;
					py = blendImageMaxY - glyphMaxY;
					for ( x = 0; x < outWidth; ++x) {
						int y;
						for (y = 0; y < outHeight; ++y) {
							index = px + x + ((y + py) * blendWidth);
							index2 = x + (y * outWidth);
							blendImage[2 * index + 1] = copyBitmap[index2];
						}
					}
				PRINT_DEBUG("free");
				free(outlineBitmap);
				free(copyBitmap);
				PRINT_DEBUG("freeed");

					outWidth  = blendWidth;
					outHeight = blendHeight;
					tempDef.width = outWidth;
					tempDef.height = outHeight;
					tempDef.offsetX = blendImageMinX;
					tempDef.offsetY =  - blendImageMaxY + outlineSize;
					buffer = blendImage;
					PRINT_DEBUG("ok");
				}
				else {
					buffer = NULL;
				}
			}
			else {
				tempDef.width = (metrics.width >> 6);
				tempDef.height = (metrics.height >> 6);
				tempDef.offsetX = (metrics.horiBearingX >> 6);
				tempDef.offsetY = -(metrics.horiBearingY >> 6);
			}


			tempDef.width += _letterEdgeExtend;
			tempDef.height += _letterEdgeExtend;
			tempDef.offsetX += adjustForExtend;
			tempDef.offsetY = _fontAscender + tempDef.offsetY - adjustForExtend;

			if (buffer) {
				if (outHeight > _currLineHeight) {
					_currLineHeight = outHeight + _letterEdgeExtend + 1 + outlineSize;
				}

				if (_currentPageOrigX + tempDef.width > textureSize) {
					_currentPageOrigY += _currLineHeight;
					_currLineHeight = 0;
					_currentPageOrigX = 0;
				}
				if (_currentPageOrigY + _lineHeight >= textureSize){
					PRINT_DEBUG ("No space in texture for char");
					invalidChar = 1;

					if (_currentPageOrigY + 12 >= textureSize){
						PRINT_DEBUG ("No more space in texture");
						textureIsOver = 1;
					}
				}

				if (invalidChar == 0) {
					PRINT_DEBUG("render %u %u", outWidth, outHeight);
					renderCharAt(_currentPageData, _currentPageOrigX + adjustForExtend, _currentPageOrigY + adjustForExtend, buffer, outWidth, outHeight);
				}
			}
			else {
				invalidChar = 1;
			}

			tempDef.x = _currentPageOrigX;
			tempDef.y = _currentPageOrigY;
			tempDef.textureID = _currentPage;
			_currentPageOrigX += tempDef.width + 1;
		}
		else{

			if (!(tempDef.xAdvance && tempDef.xAdvance > 0)) {
				invalidChar = 1;
			}

			tempDef.width = 0;
			tempDef.height = 0;
			tempDef.x = 0;
			tempDef.y = 0;
			tempDef.offsetX = 0;
			tempDef.offsetY = 0;
			tempDef.textureID = 0;
			_currentPageOrigX += 1;
		}

		if (invalidChar==0) {
			mlChar = caml_alloc_tuple(9);

			PRINT_DEBUG("Ret char");
			Store_field(mlChar,0, Val_int(code));
			Store_field(mlChar,1,caml_copy_double(tempDef.x));
			Store_field(mlChar,2,caml_copy_double(tempDef.y));
			Store_field(mlChar,3,caml_copy_double(tempDef.width));
			Store_field(mlChar,4,caml_copy_double(tempDef.height));
			Store_field(mlChar,5,caml_copy_double(tempDef.offsetX));
			Store_field(mlChar,6,caml_copy_double(tempDef.offsetY));
			Store_field(mlChar,7,caml_copy_double(tempDef.xAdvance));
			Store_field(mlChar,8,caml_copy_string(face->family_name));


			mlCharOpt = caml_alloc(1, 0);
			Store_field( mlCharOpt, 0, mlChar );
			CAMLreturn( mlCharOpt);

		}
		else {
			CAMLreturn(Val_int(0));
		}
}

