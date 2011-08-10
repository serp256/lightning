

#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include "mlwrapper_android.h"
#include "libpng/png.h"
#include "texture_common.h"
#include "libjpeg/jpeglib.h"



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
	if( row_pointer[1] == NULL ){
		fclose(fp);
		failwith("jpg: can't allocate memory for storing one row struct");
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
	unsigned long location = 0;
	int i = 0;
	unsigned int bytesPerRow = cinfo.image_width * cinfo.num_components;
	unsigned int bytesPerLegalRow = legalWidth * cinfo.num_components;
	unsigned int rowShift = legalWidth - cinfo.image_width;
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

	tInfo->format = SPTextureFormatRGB;
	tInfo->width = legalWidth;
	tInfo->realWidth = cinfo.image_width;
	tInfo->height = legalHeight;
	tInfo->realHeight = cinfo.image_height;
	tInfo->numMipmaps = 0;
	tInfo->premultipliedAlpha = 0;
	tInfo->scale = 1.;
	tInfo->dataLen = dataLen;
	tInfo->imgData = pImageData;
	return 1;
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
		failwith("png: can't allocate png read struct");
	}
	// init png_info
	info_ptr = png_create_info_struct(png_ptr);
	if(info_ptr == NULL ){
		fclose(fp);
		png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
		failwith("png: can't create info struct");
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
		DEBUGF("row diff: %d",rowDiff);
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

	tInfo->format = hasAlpha ? SPTextureFormatRGBA : SPTextureFormatRGB;
	tInfo->width = legalWidth;
	tInfo->realWidth = width;
	tInfo->height = legalHeight;
	tInfo->realHeight =  height;
	tInfo->numMipmaps = 0;
	tInfo->premultipliedAlpha = preMulti;
	tInfo->scale = 1.;
	tInfo->dataLen = dataLen;
	tInfo->imgData = pImageData;
	return 1;
}

CAMLprim value ml_loadImage(value oldTextureID, value fname, value scale) { // scale unused here
	CAMLparam2(fname,scale);
	CAMLlocal1(res);
	DEBUG("LOAD IMAGE FROM ML");
	resource r;
	if (!getResourceFd(fname,&r)) caml_raise_with_string(*caml_named_value("File_not_exists"), String_val(fname));
	// here use ext for select img format
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
	textureInfo tInfo;
  if (strcmp(ext,jpg)==0) 
	{
		if (!load_jpg_image(&r,&tInfo)) caml_failwith("can't load jpg");
	  DEBUG("JPG LOADED");
	} else {
  	if (strcmp(ext,png)==0) {
			if (!load_png_image(&r,&tInfo)) caml_failwith("can't load png");
	    DEBUG("PNG LOADED");
		} else {
			caml_failwith("can't understand img format (by ext), supported .png and .jpg only");
		};
	};
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
	Store_field(res,9,Val_int(textureID));
	CAMLreturn(res);

}


