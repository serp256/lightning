

#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include "mlwrapper_android.h"
#include "libpng/png.h"
#include "texture.h"

value load_png_image(resource *rs) { //{{{
	CAMLparam0();
	CAMLlocal2(oImgData,result);
	png_structp png_ptr;
	png_infop info_ptr;
	png_uint_32 width, height;
	int bit_depth, color_type, interlace_type;
	FILE *fp = fdopen(rs->fd,"rb");
	size_t rowbytes;

	 png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	// (void *)user_error_ptr, user_error_fn, user_warning_fn);

	if( png_ptr == NULL ){
		fclose(fp);
		failwith("png: can't allocate png read struct");
	}

	info_ptr = png_create_info_struct(png_ptr);
	if(info_ptr == NULL ){
		fclose(fp);
		png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
		failwith("png: can't create info struct");
	}

	// error handling 
	if (setjmp(png_jmpbuf(png_ptr))) {
		// Free all of the memory associated with the png_ptr and info_ptr
		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
		fclose(fp);
		// If we get here, we had a problem reading the file 
		failwith("png: read error");
	}

	// use standard C stream
	png_init_io(png_ptr, fp);

	// png_set_sig_bytes(png_ptr, sig_read (= 0) );

	png_read_info(png_ptr, info_ptr);

	png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type, &interlace_type, NULL, NULL);

	/*
	if (oversized(width, height)){
		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
		fclose(fp);
		failwith_oversized("png");
	} */

	/*
	if (color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_GRAY_ALPHA) png_set_gray_to_rgb(png_ptr);
	if (color_type & PNG_COLOR_TYPE_PALETTE ) png_set_expand(png_ptr);
	if (bit_depth == 16 ) png_set_strip_16(png_ptr);
	if (color_type & PNG_COLOR_MASK_ALPHA ) png_set_strip_alpha(png_ptr);
	*/

	png_read_update_info(png_ptr, info_ptr);
	png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type, &interlace_type, NULL, NULL);

	/*
	if (color_type != PNG_COLOR_TYPE_RGB || bit_depth != 8 ) {
		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
		fclose(fp);
		failwith("png: unsupported color type");
	}
	*/

	rowbytes = png_get_rowbytes(png_ptr, info_ptr);

	// rowbytes * height should be the maximum malloc size in this function
	/*
	if (oversized(rowbytes, height) || oversized(sizeof(png_bytep), height)){
		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
		fclose(fp);
		failwith("png error: image contains oversized or bogus width and height");
	}*/
	
	int i;
	png_bytep *row_pointers;
	unsigned char * buf;

	row_pointers = (png_bytep*) stat_alloc(sizeof(png_bytep) * height);
	int dataLen = rowbytes * height;
	buf = stat_alloc(dataLen);
	for( i = 0; i < height; i ++ ){
		row_pointers[height - i - 1] = buf + rowbytes * i;
	}

	/*
	png_set_rows(png_ptr, info_ptr, row_pointers);

	// Later, we can return something 
	if (setjmp(png_jmpbuf(png_ptr))) {
		// Free all of the memory associated with the png_ptr and info_ptr
		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
		fclose(fp);
		// If we get here, we had a problem reading the file
		//fprintf(stderr, "png short file\n");
		stat_free(row_pointers);
		stat_free(buf);
		caml_failwith("png: short file");
		CAMLreturn(result);
	}*/

	png_read_image(png_ptr, row_pointers);
	png_read_end(png_ptr, info_ptr);
	png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);

	/*
	r = alloc_tuple(height);
	for( i = 0; i < height; i ++ ){
		tmp = caml_alloc_string(rowbytes);
		memcpy(String_val(tmp), buf+rowbytes*i, rowbytes);
		Store_field( r, i, tmp );
	}
	res = alloc_tuple(3);
	Store_field( res, 0, Val_int(width) );
	Store_field( res, 1, Val_int(height) );
	Store_field( res, 2, r );
	*/

	/* close the file */
	fclose(fp);

	stat_free((void*)row_pointers);
	int legalWidth = width;
	int legalHeight = height;

	intnat dims[1];
	dims[0] = dataLen;
	oImgData = caml_ba_alloc(CAML_BA_MANAGED | CAML_BA_UINT8, 1, buf, dims); 

	/*
	int k,l;
	for (k = 0; k < height; k++) {
		for (l = 0; l < width; l++) {
			int j = ((k * width) + l)*4;
			DEBUGF("[%hhd:%hhd:%hhd:%hhd]",buf[j],buf[j+1],buf[j+2],buf[j+3]);
		}
	};
	*/
	

	result = caml_alloc_tuple(10);
	Store_field(result,0,Val_int(SPTextureFormatRGBA));
	Store_field(result,1,Val_int((unsigned int)width));
	Store_field(result,2,Val_int(legalWidth));
	Store_field(result,3,Val_int((unsigned int)height));
	Store_field(result,4,Val_int(legalHeight));
	Store_field(result,5,Val_int(0));
	Store_field(result,6,Val_int(1));
	Store_field(result,7,Val_int(0));
	Store_field(result,8,caml_copy_double(1.));
	Store_field(result,9,oImgData);
	CAMLreturn(result);
} //}}}

CAMLprim value ml_loadImage(value fname, value scale) { // scale unused here
	CAMLparam2(fname,scale);
	resource r;
	if (!getResourceFd(fname,&r)) caml_raise_with_string(*caml_named_value("File_not_exists"), String_val(fname));
	// here use ext for select img format, but now we work only with png
	value res = load_png_image(&r);
	CAMLreturn(res);
}


