#include "texture_save.h"
#include <stdlib.h>
#include <caml/fail.h>
#include "light_common.h"
#include <caml/memory.h>
#ifdef ANDROID
#include "android/libpng/png.h"
#else
#include "png.h"
#endif

int save_png_image(value name, char* buffer, unsigned int width, unsigned int height) {

  FILE *fp;
  png_structp png_ptr;
  png_infop info_ptr;

  if (( fp = fopen(String_val(name), "wb")) == NULL ){
		caml_stat_free(buffer);
    //caml_failwith("png file open failed");
		PRINT_ERROR("png file open failed");
		return 0;
  }

  if ((png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)) == NULL ){
    fclose(fp);
		caml_stat_free(buffer);
		PRINT_ERROR("png_create_write_struct");
		return 0;
    //caml_failwith("png_create_write_struct");
  }

  if( (info_ptr = png_create_info_struct(png_ptr)) == NULL ){
    fclose(fp);
    png_destroy_write_struct(&png_ptr, (png_infopp)NULL);
		caml_stat_free(buffer);
    //caml_failwith("png_create_info_struct");
		PRINT_ERROR("png_create_info_struct");
		return 0;
  }

  /* error handling */
  if (!png_jmpbuf(png_ptr)) {
    /* Free all of the memory associated with the png_ptr and info_ptr */
    png_destroy_write_struct(&png_ptr, &info_ptr);
    fclose(fp);
		caml_stat_free(buffer);
    /* If we get here, we had a problem writing the file */
    //caml_failwith("png write error");
    PRINT_ERROR("png write error");
		return 0;
  }

  /* use standard C stream */
  png_init_io(png_ptr, fp);

  /* we use system default compression */
  /* png_set_filter( png_ptr, 0, PNG_FILTER_NONE |
     PNG_FILTER_SUB | PNG_FILTER_PAETH ); */
  /* png_set_compression...() */

  png_set_IHDR( png_ptr, info_ptr, width, height,
                8 /* fixed */,
                PNG_COLOR_TYPE_RGB_ALPHA /*: PNG_COLOR_TYPE_RGB*/, /* fixed */
                PNG_INTERLACE_ADAM7,
                PNG_COMPRESSION_TYPE_DEFAULT,
                PNG_FILTER_TYPE_DEFAULT );

  /* infos... */

  png_write_info(png_ptr, info_ptr);

  {
    int rowbytes, i;
    png_bytep *row_pointers;

    row_pointers = (png_bytep*)caml_stat_alloc(sizeof(png_bytep) * height);

    rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    for(i=0; i < height; i++){
      row_pointers[i] = (png_bytep)(buffer + rowbytes * i);
    }

    png_write_image(png_ptr, row_pointers);
    caml_stat_free((void*)row_pointers);
  }

  png_write_end(png_ptr, info_ptr);
  png_destroy_write_struct(&png_ptr, &info_ptr);

  fclose(fp);
	caml_stat_free(buffer);
	return 1;
}
