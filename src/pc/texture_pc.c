#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/threads.h>
#include <sys/stat.h>

#include "texture_load.h"


static char* resourcePath = "Resources/";

/////////////////////
// TODO: Add support of DDS
/////////////////////


int load_image_info(char *fname,char* suffix, int use_pvr, textureInfo *tInfo) {
	PRINT_DEBUG("load_image_info: %s[%s]",fname,suffix);
	char *path;
	char *ext = strrchr(fname,'.');
	size_t flen = strlen(fname);
	if (flen > 8 && fname[0] == 'S' && fname[1] == 't' && fname[2] == 'o' && fname[3] == 'r' && fname[4] == 'a' && fname[5] == 'g' && fname[6] == 'e' && fname[7] == '/')  path = fname; // it's absolute path
	else {
		int rplen = strlen(resourcePath);
		// try pallete first
		char *ext = strrchr(fname,'.');
		int slen = suffix == NULL ? 0 : strlen(suffix);
		if (ext && ext != fname && strcasecmp(ext,".plt")) {
			if (!strcasecmp(ext,".plx")) {
				// нужно загрузить палитровую картинку нахуй
				char *path = malloc(rplen + flen + slen + 1);
				memcpy(path,resourcePath,rplen);
				if (slen != 0) {// need check with prefix first
					int bflen = flen - strlen(ext);
					memcpy(path + rplen,fname,bflen);
					memcpy(path + rplen + bflen,suffix,slen);
					strcpy(path + rplen + bflen + slen,ext);
					struct stat s;
					if (!stat(path,&s)) {
						int r = loadPlxFile(path,tInfo);
						//strlcpy(tInfo->path,path,255);
						free(path);
						return r;
					}
				}
				strcpy(path + rplen,fname);
				int r = loadPlxFile(path,tInfo);
				free(path);
				return r;
			} else {
				int with_lum = !strcasecmp(ext,".lumal");

				if (!strcasecmp(ext,".alpha") || with_lum) {
					// загрузить альфу 
					char *path = malloc(rplen + flen + slen + 1);
					memcpy(path,resourcePath,rplen);
					if (slen != 0) {
						int bflen = flen - strlen(ext);
						memcpy(path + rplen,fname,bflen);
						memcpy(path + rplen + bflen,suffix,slen);
						strcpy(path + rplen + bflen + slen,ext);
						struct stat s;
						if (!stat(path,&s)) {
							int r = loadAlphaFile(path, tInfo, with_lum);
							//strlcpy(tInfo->path,path,255);
							free(path);
							return r;
						}
					}
					strcpy(path + rplen,fname);
					int r = loadAlphaFile(path, tInfo, with_lum);
					free(path);
					return r;
				} else {
					// проверить этот ебанный plx 
					int bflen = flen - strlen(ext);
					char *plxpath = malloc(rplen + bflen + slen + 5);
					memcpy(plxpath,resourcePath,rplen);
					memcpy(plxpath + rplen,fname,bflen);
					if (slen != 0) {
						memcpy(plxpath + rplen + bflen,suffix,slen);
						strcpy(plxpath + rplen + bflen + slen,".plx");
						struct stat s;
						if (!stat(plxpath,&s)) {
							int r = loadPlxFile(plxpath,tInfo);
							//strlcpy(tInfo->path,plxpath,255);
							free(plxpath);
							return r;
						}
					}
					strcpy(plxpath + rplen + bflen,".plx");
					struct stat s;
					if (!stat(plxpath,&s)) {// есть plx файл
						int r = loadPlxFile(plxpath,tInfo);
						//strlcpy(tInfo->path,plxpath,255);
						free(plxpath);
						return r;
					};
					free(plxpath);
				}				
			}
		};
		path = malloc(rplen + flen + slen + 1);
		memcpy(path,resourcePath,rplen);
		while (1) {
			if (slen != 0) {
				if (ext) {
					int bflen = flen - strlen(ext);
					memcpy(path + rplen,fname,bflen);
					memcpy(path + rplen + bflen,suffix,slen);
					strcpy(path + rplen + bflen + slen,ext);
				} else {
					int flen = flen;
					memcpy(path + rplen,fname,flen);
					strcpy(path + rplen + flen,suffix);
				}
				struct stat s;
				fprintf(stderr,"try with '%s'\n",path);
				if (!stat(path,&s)) break;
			}
			strcpy(path + rplen,fname);
			break;
		}
	};
	fprintf(stderr,"LOAD IMAGE: %s\n",path);
	int fd = open(path,O_RDONLY);
	if (fd < 0) return 2;
	int res;
	if (ext && !strcasecmp(ext,".jpg")) res = load_jpg_image(fd,tInfo);
	else res = load_png_image(fd,tInfo);
	return res;
}


/*
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
*/

/*
void ml_free_image_info(value tInfo) {
	//SDL_FreeSurface(((textureInfo*)tInfo)->surface);
	free(((textureInfo*)tInfo)->imgData);
	free((textureInfo*)tInfo);
}
*/

value ml_loadImage(value oldTextureID,value opath,value osuffix,value filter,value use_pvr) {
	PRINT_DEBUG("ml_loadImage");
	CAMLparam3(oldTextureID,opath,osuffix);
	CAMLlocal1(mlTex);
	textureInfo tInfo;
	char *suffix = Is_block(osuffix) ? String_val(Field(osuffix,0)) : NULL;
	int r = load_image_info(String_val(opath),suffix,Bool_val(use_pvr),&tInfo);
	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_raise_with_arg(*caml_named_value("Cant_load_texture"),opath);
	};
	value textureID = createGLTexture(oldTextureID,&tInfo,filter);
	free(tInfo.imgData);
	// free surface
	PRINT_DEBUG("!!!!!!!%d %d", tInfo.format & 0xFFFF, LTextureFormatPallete);
	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
	PRINT_DEBUG("Field(mlTex,0) %d", Int_val(Field(mlTex,0)));
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
