

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




// FIXME: need rewrite to try all with suffix and after without
int load_image_info_old(char *fname,char *suffix,int use_pvr,textureInfo *tInfo) {
	// Проверить фсю хуйню
	DEBUGF("LOAD IMAGE INFO: %s[%s]",fname,suffix);
	char *ext = strrchr(fname,'.');
	resource r;
	int slen = suffix == NULL ? 0 : strlen(suffix);
	char *path;
	if (ext && ext != fname ) {
		DEBUGF("ext is %s",ext);
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
					strcpy(path + bflen + slen, ".pvr");
					if (getResourceFd(path,&r)) {
						FILE *fptr = fdopen(r.fd,"rb");
						int res = loadPvrFile3(fptr,r.length,tInfo);
						fclose(fptr);
						free(path);
						return res;
					}
				};
				strcpy(path + bflen, ".pvr");
				if (getResourceFd(path,&r)) {
					FILE *fptr = fdopen(r.fd,"rb");
					int res = loadPvrFile3(fptr,r.length,tInfo);
					DEBUG("PVR File Loaded");
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

int load_image_info(char *fname,char *suffix,int use_pvr,textureInfo *tInfo) {
	// Проверить фсю хуйню
	DEBUGF("LOAD IMAGE INFO: %s[%s]",fname,suffix);
	char *ext = strrchr(fname,'.');
	resource r;
	int slen = suffix == NULL ? 0 : strlen(suffix);
	char *path;
	if (ext && ext != fname ) {
		DEBUGF("ext is %s",ext);
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
			
			if (slen != 0) { //with suffix
				if (use_pvr) { // pvr
					strcpy(path + bflen + slen, ".pvr");
					DEBUGF("TRY GET IMAGE %s", path);
					if (getResourceFd(path,&r)) {
						FILE *fptr = fdopen(r.fd,"rb");
						int res = loadPvrFile3(fptr,r.length,tInfo);
						fclose(fptr);
						free(path);
						return res;
					}
				};

				strcpy(path + bflen + slen, ".plx"); //plx
				DEBUGF("TRY GET IMAGE %s", path);
				if (getResourceFd(path,&r)) {
					free(path);
					gzFile fptr = gzdopen(r.fd,"rb");
					return loadPlxPtr(fptr,tInfo);
				}
				if (!strcasecmp(ext,".jpg")) {
						strcpy(path + bflen + slen, ext);
						if (getResourceFd(path,&r)) {
							free(path);
							return load_jpg_image(r.fd,tInfo);
						}
				};
				if (!strcasecmp(ext,".png")) {
						strcpy(path + bflen + slen, ext);
						if (getResourceFd(path,&r)) {
							free(path);
							return load_png_image(r.fd,tInfo);
						}
				};
			};

			if (use_pvr) { //pvr withoud suffix 
				strcpy(path + bflen, ".pvr");
				DEBUGF("TRY GET IMAGE %s", path);
				if (getResourceFd(path,&r)) {
					FILE *fptr = fdopen(r.fd,"rb");
					int res = loadPvrFile3(fptr,r.length,tInfo);
					DEBUG("PVR File Loaded");
					fclose(fptr);
					free(path);
					return res;
				};
			};
			// try plx
			strcpy(path + bflen, ".plx");
			DEBUGF("TRY GET IMAGE %s", path);
			if (getResourceFd(path,&r)) {
				free(path);
				gzFile fptr = gzdopen(r.fd,"rb");
				return loadPlxPtr(fptr,tInfo);
			};

			if (!strcasecmp(ext,".jpg")) {
				free(path);
				DEBUGF("TRY GET IMAGE %s", fname);
				if (!getResourceFd(fname,&r)) return 2;
				return load_jpg_image(r.fd,tInfo);
			};
		};
	} else { // нету блядь  расширения нахуй
		if (slen > 0) { 
			int flen = strlen(fname);
			path = malloc(flen + slen);
			memcpy(path,fname,flen);
			strcpy(path + flen,suffix);
		} 
	}

	DEBUGF("FINAL TRY GET IMAGE %s", fname);
	if (!getResourceFd(fname,&r)) return 2;

	return load_png_image(r.fd,tInfo);
}




value ml_loadImage(value oldTextureID,value opath,value osuffix,value use_pvr,value filter) {
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
	ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
	//SDL_FreeSurface(tInfo.surface);
	CAMLreturn(mlTex);
}

