
#include <SDL_image.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/threads.h>
#include "texture_common.h"



int _load_image(char *path,textureInfo *tInfo) {
	SDL_Surface* s = IMG_Load(path);
	if (s == NULL) return 2;
	int width = s->w;
	int height = s->h;
  int legalWidth = nextPowerOfTwo(width);
  int legalHeight = nextPowerOfTwo(height);
	SDL_Surface *surface;
	fprintf(stderr,"%s - bpp = %d\n",path,s->format->BitsPerPixel);
	switch (s->format->BitsPerPixel) {
		case 32:
			tInfo->format = SPTextureFormatRGBA;
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	Uint32 rmask = 0xff000000;
	Uint32 gmask = 0x00ff0000;
	Uint32 bmask = 0x0000ff00;
	Uint32 amask = 0x000000ff;
#else
	Uint32 rmask = 0x000000ff;
	Uint32 gmask = 0x0000ff00;
	Uint32 bmask = 0x00ff0000;
	Uint32 amask = 0xff000000;
#endif
			surface = SDL_CreateRGBSurface(0, legalWidth, legalHeight, 32, rmask,gmask,bmask,amask);
			SDL_SetSurfaceBlendMode(s,SDL_BLENDMODE_NONE);
			if (SDL_BlitSurface(s, NULL, surface, NULL) < 0) {
				SDL_FreeSurface(s);
				SDL_FreeSurface(surface);
				return 1;
			};
			SDL_FreeSurface(s);
			break;
		case 24:
				tInfo->format = SPTextureFormatRGB;
				surface = s;
				break;
		default:
				SDL_FreeSurface(s);
				return 1;
	};
	tInfo->width = legalWidth;
	tInfo->realWidth = width;
	tInfo->height = legalHeight;
	tInfo->realHeight = height;
	tInfo->generateMipmaps = 0;
	tInfo->numMipmaps = 0;
	tInfo->scale = 1.;
	tInfo->dataLen = surface->w * surface->h * (surface->format->BitsPerPixel / 8);
	tInfo->imgData = surface->pixels;
	tInfo->surface = surface;
	return 0;
}


value ml_load_image_info(value opath) {
	char *path = malloc(caml_string_length(opath) + 1);
	strcpy(path,String_val(opath));
	textureInfo *tInfo = malloc(sizeof(textureInfo));

	caml_release_runtime_system();

	int r = _load_image(path,tInfo);

	caml_acquire_runtime_system();

	if (r) {
		free(tInfo);
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};

	return ((value)tInfo);
}

void ml_free_image_info(value tInfo) {
	SDL_FreeSurface(((textureInfo*)tInfo)->surface);
	free((textureInfo*)tInfo);
}


value ml_loadImage(value oldTextureID,value opath,value scale) {
	CAMLparam3(oldTextureID,opath,scale);
	CAMLlocal1(mlTex);
	textureInfo tInfo;
	int r = _load_image(String_val(opath),&tInfo);
	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};
	GLuint textureID = createGLTexture(OPTION_INT(oldTextureID),&tInfo);
	// free surface
	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
	SDL_FreeSurface(tInfo.surface);
	CAMLreturn(mlTex);
}



/*
CAMLprim value ml_loadTexture(value mlTexInfo, value imgData) {
	CAMLparam2(mlTexInfo,imgData);
	textureInfo tInfo;
	tInfo.format = Long_val(Field(mlTexInfo,0));
	tInfo.realWidth = Long_val(Field(mlTexInfo,1));
	tInfo.width = Long_val(Field(mlTexInfo,2));
	tInfo.realHeight = Long_val(Field(mlTexInfo,3));
	tInfo.height = Long_val(Field(mlTexInfo,4));
	tInfo.numMipmaps = Long_val(Field(mlTexInfo,5));
	tInfo.generateMipmaps = Int_val(Field(mlTexInfo,6));
	tInfo.premultipliedAlpha = Int_val(Field(mlTexInfo,7));
	tInfo.scale = Double_val(Field(mlTexInfo,8));
	struct caml_ba_array *data = Caml_ba_array_val(imgData);
	tInfo.dataLen = data->dim[0];
	tInfo.imgData = data->data;
	unsigned int texID = createGLTexture(Long_val(Field(mlTexInfo,9)),&tInfo);
	if (!texID) caml_failwith("failed to load texture");
	Store_field(mlTexInfo,9,Val_long(texID));
	CAMLreturn(mlTexInfo);
}
*/
