
#include <SDL_image.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/threads.h>
#include "texture_common.h"



int load_image_info(char *path,textureInfo *tInfo) {
	fprintf(stderr,"LOAD IMAGE: %s\n",path);
	SDL_Surface* s = IMG_Load(path);
	if (s == NULL) return 2;
	int width = s->w;
	int height = s->h;
  int legalWidth = nextPowerOfTwo(width);
  int legalHeight = nextPowerOfTwo(height);
	SDL_Surface *surface;
	unsigned int dataLen = legalWidth * legalHeight * (s->format->BitsPerPixel / 8);
	unsigned char *pixels = (unsigned char*)malloc(dataLen);
	switch (s->format->BitsPerPixel) {
		case 32:
			tInfo->format = LTextureFormatRGBA;
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
	// FIXME: We can map it manually
			surface = SDL_CreateRGBSurface(0, legalWidth, legalHeight, 32, rmask,gmask,bmask,amask);
			SDL_SetSurfaceBlendMode(s,SDL_BLENDMODE_NONE);
			if (SDL_BlitSurface(s, NULL, surface, NULL) < 0) {
				SDL_FreeSurface(s);
				SDL_FreeSurface(surface);
				return 1;
			};
			SDL_FreeSurface(s);
			// premiltiplyAlpha
			int i;
			float a;
			unsigned char *spixels = surface->pixels;
			for (i = 0; i < legalWidth * legalHeight; i++) {
				pixels[i*4 + 3] = spixels[i*4 + 3];
				a = (float)(pixels[i*4 + 3]) / 255.0;
				pixels[i*4] = (unsigned char)((float)(spixels[i*4]) * a);
				pixels[i*4 + 1] = (unsigned char)((float)(spixels[i*4 + 1]) * a);
				pixels[i*4 + 2] = (unsigned char)((float)(spixels[i*4 + 2]) * a);
			}
			SDL_FreeSurface(surface);
			break;
		case 24:
				return 1; // FIXME
				tInfo->format = LTextureFormatRGB;
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
	tInfo->premultipliedAlpha = 1;
	tInfo->generateMipmaps = 0;
	tInfo->numMipmaps = 0;
	tInfo->scale = 1.;
	tInfo->dataLen = dataLen;
	tInfo->imgData = pixels;
	return 0;
}


value ml_load_image_info(value opath) {
	char *path = malloc(caml_string_length(opath) + 1);
	strcpy(path,String_val(opath));
	textureInfo *tInfo = malloc(sizeof(textureInfo));

	caml_release_runtime_system();

	int r = load_image_info(path,tInfo);

	caml_acquire_runtime_system();
	fprintf(stderr,"IMAGE INFO LOADED: %s\n",path);
	free(path);

	if (r) {
		free(tInfo);
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};

	return ((value)tInfo);
}

/*
void ml_free_image_info(value tInfo) {
	//SDL_FreeSurface(((textureInfo*)tInfo)->surface);
	free(((textureInfo*)tInfo)->imgData);
	free((textureInfo*)tInfo);
}
*/

value ml_loadImage(value oldTextureID,value opath,value scale) {
	CAMLparam3(oldTextureID,opath,scale);
	CAMLlocal1(mlTex);
	textureInfo tInfo;
	int r = load_image_info(String_val(opath),&tInfo);
	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_failwith("Can't load image");
	};
	GLuint textureID = createGLTexture(OPTION_INT(oldTextureID),&tInfo);
	// free surface
	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
	//SDL_FreeSurface(tInfo.surface);
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
