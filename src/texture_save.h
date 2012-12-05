
#ifndef __TEXTURE_SAVE_H__
#define __TEXTURE_SAVE_H__
#include <caml/mlvalues.h>

int save_png_image(value name, char* buffer, unsigned int width, unsigned int height);

#endif
