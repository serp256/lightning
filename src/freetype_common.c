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
#include FT_STROKER_H
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
int _outlineSize = 0;
void renderCharAt(unsigned char *dest,int posX, int posY, unsigned char* bitmap,long bitmapWidth,long bitmapHeight)
{
    int iX = posX;
    int iY = posY;
		long y;
		int x;

		if(_outlineSize > 0) {
				unsigned char tempChar;
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
				free(bitmap);
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

int outline = 0;
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

value ml_freetype_setStroke(value vstroke) {
	CAMLparam1(vstroke);
	outline = Int_val(vstroke);
	CAMLreturn0;
}

void initTextureData () {
		PRINT_DEBUG("1");
		free(_currentPageData);
		PRINT_DEBUG("1 %i",_currentPageDataSize);
		_currentPageData= malloc(_currentPageDataSize);
		PRINT_DEBUG("1");
		if (!_currentPageData) {
				caml_failwith(caml_copy_string("Freetype: not enough memory"));
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

				glGetIntegerv(GL_MAX_TEXTURE_SIZE,&textureSize);
				adjustForExtend = _letterEdgeExtend / 2;
				_currentPageDataSize = textureSize * textureSize;//textureSize * textureSize;
				_currentPageDataSize = outline > 0 ?  _currentPageDataSize* 2 : _currentPageDataSize; 
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

	if (outline > 0) {
		_outlineSize = outline;
		FT_Stroker_New(_FTlibrary, &stroker);
		FT_Stroker_Set(stroker,
				(int)(_outlineSize * 64),
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

		tInfo->format = outline > 0 ?  LTextureLuminanceAlpha :LTextureFormatAlpha;
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

value ml_freetype_bindTexture(value unit) {
	CAMLparam0();

	PRINT_DEBUG("FT bindTexture");
	glBindTexture(GL_TEXTURE_2D, texID);

	if (outline>0) {
		PRINT_DEBUG("outline");
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, textureSize, textureSize, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);
	}
	else {
		glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, textureSize, textureSize, 0, GL_ALPHA, GL_UNSIGNED_BYTE, _currentPageData);
	}
	PRINT_DEBUG("end");
	initTextureData();
	CAMLreturn(Val_unit);
}


///////////////////////////
typedef struct {
  int w;
  int h;
  unsigned char* buf;
  int bearingx;
  int bearingy;
  int minx;
  int miny;
} stroke_t;

typedef struct {
  int x;
  int y;
  int len;
  int val;
} span_t;

typedef struct {
  int len;
  int size;
  int minx;
  int miny;
  int maxx;
  int maxy;
  span_t* items;
} spans_t;

spans_t* spans_create() {
  spans_t* retval = (spans_t*)malloc(sizeof(spans_t));
  retval->len = 0;
  retval->size = 10;
  retval->minx = 10000000;
  retval->miny = 10000000;
  retval->maxx = -10000000;
  retval->maxy = -10000000;
  retval->items = (span_t*)malloc(sizeof(span_t) * retval->size);

  return retval;
}

void spans_add(spans_t* spans, int x, int y, int len, int val) {
  if (spans->len == spans->size) {
    spans->size += 10;
    spans->items = (span_t*)realloc(spans->items, sizeof(span_t) * spans->size);
  }

  span_t* span = spans->items + spans->len;
  span->x = x;
  span->y = y;
  span->len = len;
  span->val = val;

  spans->minx = spans->minx > x ? x : spans->minx;
  spans->miny = spans->miny > y ? y : spans->miny;
  spans->maxx = spans->maxx < x + len - 1 ? x + len - 1 : spans->maxx;
  spans->maxy = spans->maxy < y ? y : spans->maxy;
  spans->len++;
}

void spans_free(spans_t* spans) {
  free(spans->items);
  free(spans);
}

void spans_to_stroke(stroke_t* stroke, spans_t* strk_spans, spans_t* glph_spans) {
  int i, j, y;
  span_t* span;

  for (i = 0; i < strk_spans->len; i++) {
    span = strk_spans->items + i;
    y = span->y - stroke->miny;

    for (j = span->x - stroke->minx; j < span->x - stroke->minx + span->len; j++) {
      *(stroke->buf + 2 * (stroke->w * y + j) + 1) = span->val;
    }
  }

  for (i = 0; i < glph_spans->len; i++) {
    span = glph_spans->items + i;
    y = span->y - stroke->miny;

    for (j = span->x - stroke->minx; j < span->x - stroke->minx + span->len; j++) {
      *(stroke->buf + 2 * (stroke->w * y + j)) = span->val;
    }
  }
}


void render(const int y,
               const int count,
               const FT_Span * const spans,
               void * const user)
{
  spans_t* spns = (spans_t*)user;

	int i;
  for (i = 0; i < count; ++i) {
    spans_add(spns, spans[i].x, y, spans[i].len, spans[i].coverage);
  }  
}
stroke_t* stroke_render (int code) {
  FT_Glyph glyph;

	unsigned int glyph_index = 	FT_Get_Char_Index(face, code);
	/*
	//int _fontAscender = face->size->metrics.ascender >> 6;
	//int _lineHeight = face->size->metrics.height >> 6;
	error = FT_Load_Glyph(face,glyph_index, FT_LOAD_RENDER | FT_LOAD_NO_AUTOHINT);
	print_error(error);
		
	unsigned char* buffer = face->glyph->bitmap.buffer;

	unsigned int w = face->glyph->bitmap.width;
	unsigned int h = face->glyph->bitmap.rows;
	unsigned int outWidth = w; 
	unsigned int outHeight = h; 

	*/

  if( FT_Load_Glyph(face, glyph_index, FT_LOAD_DEFAULT ) ){
    failwith("FT_Load_Glyph");
  }
  if (FT_Get_Glyph(face->glyph, &glyph) != 0) {
    failwith("FT_Get_Glyph");
  }

  FT_Glyph_StrokeBorder(&glyph, stroker, 0, 0);

  if (glyph->format != FT_GLYPH_FORMAT_OUTLINE) {
    failwith("glyph format is not FT_GLYPH_FORMAT_OUTLINE");
  }

  FT_Outline* outline = &(((FT_OutlineGlyph)glyph)->outline);

  FT_BBox stroke_box;
  FT_Outline_Get_CBox(outline, &stroke_box);

  spans_t* stroke_spans = spans_create();
  spans_t* glyph_spans = spans_create();

  FT_Raster_Params params;
  params.flags = FT_RASTER_FLAG_AA | FT_RASTER_FLAG_DIRECT;
  params.gray_spans = render;
  params.user = (void*)stroke_spans;

  if (FT_Outline_Render(_FTlibrary, outline, &params) != 0) {
    failwith("FT_Outline_Render");
  }

  if (face->glyph->format != FT_GLYPH_FORMAT_OUTLINE) {
    failwith("glyph format is not FT_GLYPH_FORMAT_OUTLINE"); 
  }

  outline = &face->glyph->outline;
  FT_BBox glyph_box;
  FT_Outline_Get_CBox(outline, &glyph_box);
  params.user = glyph_spans;

  if (FT_Outline_Render(_FTlibrary, outline, &params) != 0) {
    failwith("FT_Outline_Render");
  }

  int minx = MIN(stroke_spans->minx, glyph_spans->minx);
  int miny = MIN(stroke_spans->miny, glyph_spans->miny);
  int maxx = MAX(stroke_spans->maxx, glyph_spans->maxx);
  int maxy = MAX(stroke_spans->maxy, glyph_spans->maxy);

  int stroke_w = maxx - minx + 1;
  int stroke_h = maxy - miny + 1;


	//unsigned char* buf = malloc(2 * stroke_w * stroke_h);
 // memset(buf, 0, 2 * stroke_w * stroke_h);

  //vstroke = caml_alloc_custom(&stroket_ops, sizeof(stroke_t), 2 * stroke_w * stroke_h, 10485760);

	/*
  stroke_t* stroke = (stroke_t*)Data_custom_val(vstroke);
	*/
	stroke_t* stroke = malloc(sizeof(stroke_t));
  stroke->w = stroke_w;
  stroke->h = stroke_h;
  stroke->minx = minx;
  stroke->miny = miny;  
  stroke->buf = (unsigned char*)malloc(2 * stroke_w * stroke_h);
  memset(stroke->buf, 0, 2 * stroke_w * stroke_h);

  stroke->bearingx = glyph_spans->minx - stroke_spans->minx;
  stroke->bearingy = stroke_spans->maxy - glyph_spans->maxy;

  spans_to_stroke(stroke, stroke_spans, glyph_spans);
  spans_free(stroke_spans);
  spans_free(glyph_spans);

  FT_Done_Glyph(glyph);
  FT_Stroker_Done(stroker);
	return (stroke);

}


unsigned char stroke_get_pixel(stroke_t* stroke, int x, int y, int glyph) {
  //int retval = *(stroke->buf + 2 * (Int_val(vy) * stroke->w + Int_val(vx)) + (vglyph == Val_true ? 0 : 1));
	return *(stroke->buf + 2 * (y * stroke->w + x) + glyph);
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

	PRINT_DEBUG ("cur %s, load %s", current_face_name, cface);
	if (current_face_name && strlen(cface) > 0 && strcmp(current_face_name, cface) != 0) { 
		loadFace (cface, fontSize);
	}

	fontLetterDefinition tempDef;

	unsigned int glyph_index = 	FT_Get_Char_Index(face, code);
	PRINT_DEBUG ("gluph index %d", glyph_index);
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

		unsigned int w = face->glyph->bitmap.width;
		unsigned int h = face->glyph->bitmap.rows;
		 
		tempDef.xAdvance = face->glyph->metrics.horiAdvance >> 6;
		PRINT_DEBUG ("w %d h %d, %d", w, h, tempDef.xAdvance); 
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
			if (tempDef.xAdvance && tempDef.xAdvance > 0)
				tempDef.validDefinition = 0;
			else {
				tempDef.validDefinition = 1;
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

		if (tempDef.validDefinition==0) {
			mlChar = caml_alloc_tuple(9);

			Store_field(mlChar,0, Val_int(code));
			Store_field(mlChar,1,caml_copy_double(tempDef.x));
			Store_field(mlChar,2,caml_copy_double(tempDef.y));
			Store_field(mlChar,3,caml_copy_double(tempDef.width));
			Store_field(mlChar,4,caml_copy_double(tempDef.height));
			Store_field(mlChar,5,caml_copy_double(tempDef.offsetX));
			Store_field(mlChar,6,caml_copy_double(tempDef.offsetY));
			Store_field(mlChar,7,caml_copy_double(tempDef.xAdvance));
			Store_field(mlChar,8,caml_copy_string(face->family_name));

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

