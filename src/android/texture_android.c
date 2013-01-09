

#include <fcntl.h>
#include <zlib.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include "mlwrapper_android.h"
#include "texture_load.h"
#include "texture_pvr.h"
#include "mlwrapper.h"




/*
int load_image_info_old(char *fname,char *suffix,int use_pvr,textureInfo *tInfo) {
	// Проверить фсю хуйню
	PRINT_DEBUG("LOAD IMAGE INFO: %s[%s]",fname,suffix);
	char *ext = strrchr(fname,'.');
	resource r;
	int slen = suffix == NULL ? 0 : strlen(suffix);
	char *path;
	if (ext && ext != fname ) {
		PRINT_DEBUG("ext is %s",ext);
		int flen = strlen(fname);
		int elen = strlen(ext);
		int bflen = flen - elen;
		int diff = elen < 4 ? 4 - elen : 0;
		path = malloc(flen + diff + slen + 1);
		memcpy(path,fname,bflen);
		if (slen != 0) memcpy(path + bflen,suffix,slen);
		if (!strcasecmp(ext,".alpha")) {// if it's alpha, not try to add pvr, plx ...
			if (slen != 0) {
				strcpy(path + bflen + slen,ext);
				if (getResourceFd(path,&r)) {
					gzFile fptr = gzdopen(r.fd,"rb");
					int r = loadAlphaPtr(fptr,tInfo);
					free(path);
					return r;
				}
			}
			free(path);
			if (!getResourceFd(fname,&r)) return 2;
			gzFile fptr = gzdopen(r.fd,"rb");
			int r = loadAlphaPtr(fptr,tInfo);
			return r;
		} else if (strcasecmp(ext,".plt")) { // если это не палитра
			// try pvr
			if (use_pvr) {
				if (slen != 0) {
					strcpy(path + bflen + slen, compressedExt);
					if (getResourceFd(path,&r)) {
						FILE *fptr = fdopen(r.fd,"rb");
						int res = loadCompressedTexture(fptr,r.length,tInfo);
						fclose(fptr);
						free(path);
						return res;
					}
				};
				strcpy(path + bflen, compressedExt);
				if (getResourceFd(path,&r)) {
					FILE *fptr = fdopen(r.fd,"rb");
					int res = loadCompressedTexture(fptr,r.length,tInfo);
					PRINT_DEBUG("PVR File Loaded");
					fclose(fptr);
					free(path);
					return res;
				};
			};
			// try plx
			if (slen != 0) {
				strcpy(path + bflen + slen, ".plx");
				if (getResourceFd(path,&r)) {
					free(path);
					gzFile fptr = gzdopen(r.fd,"rb");
					return loadPlxPtr(fptr,tInfo);
				}
			};
			strcpy(path + bflen, ".plx");
			if (getResourceFd(path,&r)) {
				free(path);
				gzFile fptr = gzdopen(r.fd,"rb");
				return loadPlxPtr(fptr,tInfo);
			};
			if (!strcasecmp(ext,".jpg")) {
				if (slen != 0) {
					strcpy(path + bflen + slen, ext);
					if (getResourceFd(path,&r)) {
						free(path);
						return load_jpg_image(r.fd,tInfo);
					}
				};
				free(path);
				if (!getResourceFd(fname,&r)) return 2;
				return load_jpg_image(r.fd,tInfo);
			};
		};
		strcpy(path + bflen + slen,ext);
	} else { // нету блядь  расширения нахуй
		if (slen > 0) { 
			int flen = strlen(fname);
			path = malloc(flen + slen);
			memcpy(path,fname,flen);
			strcpy(path + flen,suffix);
		} 
	}

	// Treat it as png
	if (slen > 0) {
		// IN path alredy good fname!!
		if (getResourceFd(path,&r)) {
			free(path);
			return load_png_image(r.fd,tInfo);
		}
		free(path);
	};
	if (!getResourceFd(fname,&r)) return 2;

	return load_png_image(r.fd,tInfo);
}
*/

int load_image_info(char *fname,char *suffix,int use_pvr,textureInfo *tInfo) {
	PRINT_DEBUG("LOAD IMAGE INFO: %s[%s]",fname,suffix);
	if (fname[0] == '/') {
		int fd = open(fname, O_RDONLY);
		if (fd < 0) return 1;
		return load_png_image(fd,tInfo);
	};
	char *ext = strrchr(fname,'.');
	resource r;
	int slen = suffix == NULL ? 0 : strlen(suffix);
	char *path;
	if (ext && ext != fname ) {
		PRINT_DEBUG("ext is %s",ext);
		int flen = strlen(fname);
		int elen = strlen(ext);
		int bflen = flen - elen;
		int diff = elen < 4 ? 4 - elen : 0;
		path = malloc(flen + diff + slen + 1);
		memcpy(path,fname,bflen);
		if (slen != 0) memcpy(path + bflen,suffix,slen);
		if (!strcasecmp(ext,".alpha")) {// if it's alpha, not try to add pvr, plx ...
			if (slen != 0) {
				strcpy(path + bflen + slen,ext);
				if (getResourceFd(path,&r)) {
					gzFile fptr = gzdopen(r.fd,"rb");
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,path,255);
#endif
					int r = loadAlphaPtr(fptr,tInfo);
					free(path);
					return r;
				}
			}
			free(path);
			if (!getResourceFd(fname,&r)) return 2;
			gzFile fptr = gzdopen(r.fd,"rb");
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,fname,255);
#endif
			int r = loadAlphaPtr(fptr,tInfo);
			return r;
		} else if (strcasecmp(ext,".plt")) { // если это не палитра
			
			if (slen != 0) { //with suffix
				if (use_pvr) { // pvr
					strcpy(path + bflen + slen, compressedExt);
					PRINT_DEBUG("TRY GET IMAGE %s", path);
					if (getResourceFd(path,&r)) {
						FILE *fptr = fdopen(r.fd,"rb");
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,path,255);
#endif
						int res = loadCompressedTexture(fptr,r.length,tInfo);
						fclose(fptr);
						free(path);
						return res;
					}
				};

				strcpy(path + bflen + slen, ".plx"); //plx
				PRINT_DEBUG("TRY GET IMAGE %s", path);
				if (getResourceFd(path,&r)) {
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,path,255);
#endif
					free(path);
					gzFile fptr = gzdopen(r.fd,"rb");
					return loadPlxPtr(fptr,tInfo);
				}
				if (!strcasecmp(ext,".jpg")) {
						strcpy(path + bflen + slen, ext);
						if (getResourceFd(path,&r)) {
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,path,255);
#endif
							free(path);
							return load_jpg_image(r.fd,tInfo);
						}
				};
				if (!strcasecmp(ext,".png")) {
						strcpy(path + bflen + slen, ext);
						if (getResourceFd(path,&r)) {
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,path,255);
#endif
							free(path);
							return load_png_image(r.fd,tInfo);
						}
				};
			};

			if (use_pvr) { //pvr withoud suffix 
				strcpy(path + bflen, compressedExt);
				PRINT_DEBUG("TRY GET IMAGE %s", path);
				if (getResourceFd(path,&r)) {
					FILE *fptr = fdopen(r.fd,"rb");
#ifdef TEXTURE_LOAD
					strncpy(tInfo->path,path,255);
#endif
					int res = loadCompressedTexture(fptr,r.length,tInfo);
					DEBUG("PVR File Loaded");
					fclose(fptr);
					free(path);
					return res;
				};
			};
			// try plx
			strcpy(path + bflen, ".plx");
			PRINT_DEBUG("TRY GET IMAGE %s", path);
			if (getResourceFd(path,&r)) {
#ifdef TEXTURE_LOAD
				strncpy(tInfo->path,path,255);
#endif
				free(path);
				gzFile fptr = gzdopen(r.fd,"rb");
				return loadPlxPtr(fptr,tInfo);
			};

			if (!strcasecmp(ext,".jpg")) {
#ifdef TEXTURE_LOAD
				strncpy(tInfo->path,path,255);
#endif
				free(path);
				PRINT_DEBUG("TRY GET IMAGE %s", fname);
				if (!getResourceFd(fname,&r)) return 2;
				return load_jpg_image(r.fd,tInfo);
			};
		};
	} else { // нету блядь  расширения нахуй
		PRINT_DEBUG("image has no extension");
		if (slen > 0) { 
			int flen = strlen(fname);
			path = malloc(flen + slen);
			memcpy(path,fname,flen);
			strcpy(path + flen,suffix);
			return 2;
		} 
	}

	PRINT_DEBUG("FINAL TRY GET IMAGE %s", fname);
	if (!getResourceFd(fname,&r)) return 2;
#ifdef TEXTURE_LOAD
	strncpy(tInfo->path,fname,255);
#endif

	return load_png_image(r.fd,tInfo);
}

value ml_loadImage(value oldTextureID,value opath,value osuffix,value filter,value use_pvr) {
	CAMLparam3(oldTextureID,opath,osuffix);
	CAMLlocal2(mlTex, mlAlphaTex);
	textureInfo tInfo;
	char *suffix = Is_block(osuffix) ? String_val(Field(osuffix,0)) : NULL;
	int r = load_image_info(String_val(opath),suffix,Bool_val(use_pvr),&tInfo);

	if (r) {
		if (r == 2) caml_raise_with_arg(*caml_named_value("File_not_exists"),opath);
		caml_raise_with_arg(*caml_named_value("Cant_load_texture"),opath);
	};

	value textureID = createGLTexture(oldTextureID,&tInfo,filter);
	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
	free(tInfo.imgData);

	textureInfo* alphaTexInfo = loadEtcAlphaTex(&tInfo, String_val(opath), suffix, Bool_val(use_pvr));

	if (alphaTexInfo) {
		value alphaTexId = createGLTexture(1, alphaTexInfo, filter);
		ML_TEXTURE_INFO(mlAlphaTex, alphaTexId, alphaTexInfo);

		value block = caml_alloc(1, 1);
		Store_field(block, 0, mlAlphaTex);
		Store_field(mlTex, 0, block);

		free(alphaTexInfo->imgData);
		free(alphaTexInfo);
	}
	

/*	PRINT_DEBUG("LTextureFormatETC1 %d", LTextureFormatETC1);
	PRINT_DEBUG("(tInfo.format & 0xFFFF) %d", (tInfo.format & 0xFFFF));

	if ((tInfo.format & 0xFFFF) == LTextureFormatETC1) {
		textureInfo alphaTexInfo;

		char* _fname = String_val(opath);
		char* ext = strrchr(_fname, '.');
		int fnameLen = strlen(_fname);
		int extLen = strlen(ext);

		char* fname = (char*)malloc(fnameLen + 7);
		char* insertTo = fname + fnameLen - extLen;

		strcpy(fname, _fname);
		strcpy(insertTo, "_alpha");
		strcpy(insertTo + 6, ext);

		PRINT_DEBUG("fname %s", fname);

		r = load_image_info(fname, suffix, Bool_val(use_pvr), &alphaTexInfo);

		PRINT_DEBUG("r: %d", r);

		if (!r) {
			value alphaTexId = createGLTexture(Val_int(0), &alphaTexInfo, filter);
			ML_TEXTURE_INFO(mlAlphaTex, alphaTexId, (&alphaTexInfo));

			value block = caml_alloc(1, 1);
			Store_field(block, 0, mlAlphaTex);
			Store_field(mlTex, 0, block);

			free(alphaTexInfo.imgData);
		}

		free(fname);
	}*/

	CAMLreturn(mlTex);
}
