

#include <zlib.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include "mlwrapper_android.h"
#include "libpng/png.h"
#include "libjpeg/jpeglib.h"
#include "texture_common.h"
#include "texture_pvr.h"


#define CC_RGB_PREMULTIPLY_APLHA(vr, vg, vb, va) \
    (unsigned)(((unsigned)((unsigned char)(vr) * ((unsigned char)(va) + 1)) >> 8) | \
    ((unsigned)((unsigned char)(vg) * ((unsigned char)(va) + 1) >> 8) << 8) | \
    ((unsigned)((unsigned char)(vb) * ((unsigned char)(va) + 1) >> 8) << 16) | \
    ((unsigned)(unsigned char)(va) << 24))

int load_jpg_image(resource *rs,textureInfo *tInfo) {

	/* these are standard libjpeg structures for reading(decompression) */
	struct jpeg_decompress_struct cinfo;
	struct jpeg_error_mgr jerr;

	unsigned char * pImageData  = 0;
	FILE *fp = fdopen(rs->fd,"rb");
	/* libjpeg data structure for storing one row, that is, scanline of an image */
	JSAMPROW row_pointer[1];
	if (row_pointer[1] == NULL) {
		fclose(fp);
		return 1;
	}

	/* here we set up the standard libjpeg error handler */
	cinfo.err = jpeg_std_error( &jerr );
	/* setup decompression process and source, then read JPEG header */
	jpeg_create_decompress( &cinfo );
	/* this makes the library read from file */
	jpeg_stdio_src( &cinfo, fp );
	/* reading the image header which contains image information */
	jpeg_read_header( &cinfo, TRUE );
	
	/* Start decompression jpeg here */
	jpeg_start_decompress( &cinfo );

	// allocate memory and read data
	unsigned int legalWidth = nextPowerOfTwo(cinfo.image_width);
	unsigned int legalHeight = nextPowerOfTwo(cinfo.image_height);
	unsigned int dataLen = legalHeight * legalWidth * cinfo.num_components;
	pImageData = caml_stat_alloc(dataLen);
	/* now actually read the jpeg into the raw buffer */
	row_pointer[0] = (unsigned char *)malloc( cinfo.output_width*cinfo.num_components );

	/* read one scan line at a time and copy data to image info */
	//unsigned long location = 0;
	int i = 0;
	unsigned int bytesPerRow = cinfo.image_width * cinfo.num_components;
	unsigned int bytesPerLegalRow = legalWidth * cinfo.num_components;
	//unsigned int rowShift = legalWidth - cinfo.image_width;
	while( cinfo.output_scanline < cinfo.image_height )
	{
		jpeg_read_scanlines( &cinfo, row_pointer, 1 ); //now one row in row_pointer-array
		memcpy(pImageData + i * bytesPerLegalRow, row_pointer[0], bytesPerRow);
		i++;
	}
	/* wrap up decompression, destroy objects, free pointers and close open files */
	jpeg_finish_decompress( &cinfo );
	jpeg_destroy_decompress( &cinfo );
	free( row_pointer[0] );
	fclose( fp );

	tInfo->format = LTextureFormatRGB;
	tInfo->width = legalWidth;
	tInfo->realWidth = cinfo.image_width;
	tInfo->height = legalHeight;
	tInfo->realHeight = cinfo.image_height;
	tInfo->numMipmaps = 0;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = 0;
	tInfo->scale = 1.;
	tInfo->dataLen = dataLen;
	tInfo->imgData = pImageData;
	return 0;
}


int load_png_image(resource *rs,textureInfo *tInfo) {
	//png_byte        header[8]   = {0};
	png_structp     png_ptr     =   0; 
	png_infop       info_ptr    = 0;
	unsigned char * pImageData  = 0;

	FILE *fp = fdopen(rs->fd,"rb");

	// png header len is 8 bytes
	//CC_BREAK_IF(nDatalen < 8);

	// check the data is png or not
	//memcpy(header, pData, 8);
	//CC_BREAK_IF(png_sig_cmp(header, 0, 8));

	// init png_struct
	png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
	if( png_ptr == NULL ){
		fclose(fp);
		return 1;
	}
	// init png_info
	info_ptr = png_create_info_struct(png_ptr);
	if(info_ptr == NULL ){
		fclose(fp);
		png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
		return 1;
	}

	// set the read call back function
	png_init_io(png_ptr, fp);

	// read png
	// PNG_TRANSFORM_EXPAND: perform set_expand()
	// PNG_TRANSFORM_PACKING: expand 1, 2 and 4-bit samples to bytes
	// PNG_TRANSFORM_STRIP_16: strip 16-bit samples to 8 bits
	// PNG_TRANSFORM_GRAY_TO_RGB: expand grayscale samples to RGB (or GA to RGBA)

	png_read_png(png_ptr, info_ptr, 
			PNG_TRANSFORM_EXPAND | PNG_TRANSFORM_PACKING | PNG_TRANSFORM_STRIP_16 | PNG_TRANSFORM_GRAY_TO_RGB, 
			0
	);

	int         color_type  = 0;
	png_uint_32 width = 0;
	png_uint_32 height = 0;
	int         bitsPerComponent = 0;
	png_get_IHDR(png_ptr, info_ptr, &width, &height, &bitsPerComponent, &color_type, 0, 0, 0);

	// init image info
	int preMulti = 1;
	int hasAlpha = ( png_get_color_type(png_ptr, info_ptr) & PNG_COLOR_MASK_ALPHA ) ? 1 : 0;

	// allocate memory and read data
	int bytesPerComponent = 3;
	if (hasAlpha) bytesPerComponent = 4;

	unsigned int legalWidth = nextPowerOfTwo(width);
	unsigned int legalHeight = nextPowerOfTwo(height);

	unsigned int dataLen = legalHeight * legalWidth * bytesPerComponent;
	pImageData = caml_stat_alloc(dataLen);

	png_bytep * rowPointers = png_get_rows(png_ptr, info_ptr);

	// copy data to image info
	unsigned int bytesPerRow = width * bytesPerComponent;
	unsigned int i,j;


	if(hasAlpha)
	{
		unsigned int *tmp = (unsigned int *)pImageData;
		unsigned int rowDiff = legalWidth - width;
		unsigned char red,green,blue,alpha;
		for(i = 0; i < height; i++)
		{
			for(j = 0; j < bytesPerRow; j += 4)
			{
				red = rowPointers[i][j];
				green = rowPointers[i][j + 1];
				blue = rowPointers[i][j + 2];
				alpha = rowPointers[i][j + 3];
				*tmp++ = CC_RGB_PREMULTIPLY_APLHA(red, green, blue, alpha);
			}
			tmp += rowDiff;
		}
	}
	else
	{
		unsigned int bytesPerLegalRow = legalWidth * bytesPerComponent;
		for (j = 0; j < height; ++j)
		{
			memcpy(pImageData + j * bytesPerLegalRow, rowPointers[j], bytesPerRow);
		}
	}

	png_destroy_read_struct(&png_ptr, &info_ptr, 0);
	fclose(fp);

	tInfo->format = hasAlpha ? LTextureFormatRGBA : LTextureFormatRGB;
	tInfo->width = legalWidth;
	tInfo->realWidth = width;
	tInfo->height = legalHeight;
	tInfo->realHeight =  height;
	tInfo->numMipmaps = 0;
	tInfo->generateMipmaps = 0;
	tInfo->premultipliedAlpha = preMulti;
	tInfo->scale = 1.;
	tInfo->dataLen = dataLen;
	tInfo->imgData = pImageData;
	return 0;
}


int load_image_info(char *fname,char *suffix,textureInfo *tInfo) {
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
						return load_jpg_image(&r,tInfo);
					}
				};
				free(path);
				if (!getResourceFd(fname,&r)) return 2;
				return load_jpg_image(&r,tInfo);
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
			return load_png_image(&r,tInfo);
		}
		free(path);
	};
	if (!getResourceFd(fname,&r)) return 2;

	return load_png_image(&r,tInfo);
}



value ml_loadImage(value oldTextureID,value opath,value osuffix,value filter) {
	CAMLparam3(oldTextureID,opath,osuffix);
	CAMLlocal1(mlTex);
	textureInfo tInfo;
	char *suffix = Is_block(osuffix) ? String_val(Field(osuffix,0)) : NULL;
	int r = load_image_info(String_val(opath),suffix,&tInfo);
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

/*
int loadPvrFile(resource *rs, textureInfo *tInfo) {
	FILE * fildes = fdopen(rs->fd, "rb");

	if (fildes == NULL) 
	  return 0;

	PVRTextureHeader header;

	ssize_t readed = fread(&header, 1, sizeof(PVRTextureHeader), fildes);

	if (readed != sizeof(PVRTextureHeader)) {
	  fclose(fildes); 
	  return 0;
	}

	int hasAlpha = header.alphaBitMask ? 1 : 0;

	tInfo->width = tInfo->realWidth = header.width;
	tInfo->height = tInfo->realHeight = header.height;
	tInfo->numMipmaps = header.numMipmaps;
	tInfo->premultipliedAlpha = 0;
  
    switch (header.pfFlags & 0xff)
    {
      case OGL_RGB_565:
        tInfo->format = SPTextureFormat565;
        break;
      case OGL_RGBA_5551:
		tInfo->format = SPTextureFormat5551;
		break;
      case OGL_RGBA_4444:
		tInfo->format = SPTextureFormat4444;
		break;
      case OGL_RGBA_8888:
		tInfo->format = SPTextureFormatRGBA;
		break;
      case OGL_PVRTC2:
		tInfo->format = hasAlpha ? SPTextureFormatPvrtcRGBA2 : SPTextureFormatPvrtcRGB2;
		break;
      case OGL_PVRTC4:
		tInfo->format = hasAlpha ? SPTextureFormatPvrtcRGBA4 : SPTextureFormatPvrtcRGB4;
		break;
      default:
		fclose(fildes);
		return 0;
  }

  tInfo->dataLen = header.textureDataSize;
  tInfo->imgData = (unsigned char*)malloc(header.textureDataSize);

  if (!tInfo->imgData) {
    fclose(fildes);
    return 0;
  }
  readed = fread(tInfo->imgData,sizeof(char), tInfo->dataLen, fildes);
  if (readed != header.textureDataSize) {
    fclose(fildes);
    free(tInfo->imgData);
    return 0;
  }
  tInfo->scale = 1.0;
  fclose(fildes);
  return 1;
}



CAMLprim value ml_loadImage(value oldTextureID, value fname, value osuffix) { // scale unused here
	CAMLparam2(fname,scale);
	CAMLlocal1(res);
	DEBUG("LOAD IMAGE FROM ML");

	resource r;

	char tmpname[1024];
	char ext[4];
	char png[]="png";
	char jpg[]="jpg";
	char * _fname = String_val(fname);
    
	unsigned int len = 0;
	while (_fname[len] != '\0') { len++; };
	
	ext[0] = _fname[len-3];
	ext[1] = _fname[len-2];
	ext[2] = _fname[len-1];
	ext[3] = '\0';

	unsigned int i = 0;
	while (_fname[i] != '\0') {
		if (_fname[i] == '.') {
			tmpname[i] = '.';
			tmpname[i + 1] = 'p';
			tmpname[i + 2] = 'v';
			tmpname[i + 3] = 'r';
			tmpname[i + 4] = '\0';
			break;
		} else {
			tmpname[i] = _fname[i];
		}
		i++;
	}

	textureInfo tInfo;

	if (getResourceFd(caml_copy_string(tmpname) ,&r)) {
	  if (!loadPvrFile(&r, &tInfo))  caml_failwith("can't load pvr");
	  DEBUG("PVR LOADED");
	} else {	
	
		if (!getResourceFd(fname,&r)) caml_raise_with_string(*caml_named_value("File_not_exists"), String_val(fname));

		if (strcmp(ext,jpg)==0) {
		if (!load_jpg_image(&r,&tInfo)) 
			caml_failwith("can't load jpg");
			DEBUG("JPG LOADED");
		} else {
			if (strcmp(ext,png)==0) {
			if (!load_png_image(&r,&tInfo)) caml_failwith("can't load png");
			DEBUG("PNG LOADED");
		} else {
				caml_failwith("can't understand img format (by ext), supported .png and .jpg only");
			}
		}
	}
	
	unsigned int textureID = createGLTexture(Long_val(oldTextureID),&tInfo);
	DEBUG("TEXTURE CREATED");
	free(tInfo.imgData);
	if (!textureID) caml_failwith("can't load texture");
	
	res = caml_alloc_tuple(10);
	
	Store_field(res,0,Val_int(tInfo.format));
	Store_field(res,1,Val_int((unsigned int)tInfo.realWidth));
	Store_field(res,2,Val_int(tInfo.width));
	Store_field(res,3,Val_int((unsigned int)tInfo.realHeight));
	Store_field(res,4,Val_int(tInfo.height));
	Store_field(res,5,Val_int(tInfo.numMipmaps));
	Store_field(res,6,Val_int(1));
	Store_field(res,7,Val_int(tInfo.premultipliedAlpha));
	Store_field(res,8,caml_copy_double(tInfo.scale));
	Store_field(res,9,Val_long(textureID));
	CAMLreturn(res);
}
*/
