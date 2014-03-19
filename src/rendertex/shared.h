#ifndef RENDERTEX_SHARED_H
#define RENDERTEX_SHARED_H

#include "render_stub.h"
#include "common.h"

GLuint	renderbuf_shared_tex_size();
void	rendertex_shared_create(renderbuffer_t *renderbuf, uint16_t w, uint16_t h, GLuint filter, color3F *color, GLfloat alpha, value draw_func, value *tex_id);
uint8_t rendertex_shared_draw(renderbuffer_t *renderbuf, value render_inf, float new_w, float new_h, color3F *color, GLfloat alpha, value draw_func);

#endif