#include <math.h>
#include "common.h"
#include "dedicated.h"
#include "shared.h"
#include <caml/memory.h>

value rendertex_create(value vcolor, value valpha, value vkind, value vwidth, value vheight, value vdraw_func) {
	PRINT_DEBUG("!!!rendertex_create call");

	CAMLparam5(vkind, vcolor, valpha, vwidth, vheight);
	CAMLxparam1(vdraw_func);
	CAMLlocal5(vrender_inf, vtid, vtmp, vclipping, vretval);

	GLuint filter = GL_LINEAR;
	uint16_t w = (uint16_t)ceil(Double_val(vwidth));
	uint16_t h = (uint16_t)ceil(Double_val(vheight));
	GLuint tex_size = renderbuf_shared_tex_size();
	uint8_t dedicated = (w > tex_size / 2) || (h > tex_size / 2);
	PRINT_DEBUG("dedicated %d, w %d, h %d", dedicated, w, h);
	
	if (Is_block(vkind)) {
		if (Tag_val(vkind) == 0) {
			dedicated = 1;

			switch (Int_val(Field(vkind, 0))) {
				case 0: filter = GL_NEAREST; break;
				case 1: filter = GL_LINEAR; break;
				default: break;
			}
		}		
	}

	// dedicated = 1;
	PRINT_DEBUG("dedicated %d", dedicated);

	renderbuffer_t renderbuf;
	color3F color = Is_block(vcolor) ? COLOR3F_FROM_INT(Field(vcolor, 0)) : (color3F){ 0., 0., 0. };
	GLfloat alpha = Is_block(valpha) ? Double_val(Field(valpha, 0)) : 0.;

	PRINT_DEBUG("color %f,%f,%f, alpha %f", color.r, color.g, color.b, alpha);

	if (dedicated) {
		rendertex_dedicated_create(&renderbuf, w, h, filter, &color, alpha, vdraw_func, &vtid);
	} else {
		rendertex_shared_create(&renderbuf, w, h, filter, &color, alpha, vdraw_func, &vtid);
	}

	vtmp = caml_alloc(4 * Double_wosize, Double_array_tag);
	Store_double_field(vtmp, 0, renderbuf.clp.x);
	Store_double_field(vtmp, 1, renderbuf.clp.y);
	Store_double_field(vtmp, 2, renderbuf.clp.w);
	Store_double_field(vtmp, 3, renderbuf.clp.h);
	vclipping = caml_alloc_tuple(1);
	Store_field(vclipping, 0, vtmp);

	vkind = caml_alloc_tuple(1);
	Store_field(vkind, 0, Val_true);

	PRINT_DEBUG("renderbuf %d, %d, %f, %f, %d, %d, (%d, %d, %d, %d), (%f, %f, %f, %f)", renderbuf.fbid, renderbuf.tid, renderbuf.width, renderbuf.height, renderbuf.realWidth, renderbuf.realHeight, renderbuf.vp.x, renderbuf.vp.y, renderbuf.vp.w, renderbuf.vp.h, renderbuf.clp.x, renderbuf.clp.y, renderbuf.clp.w, renderbuf.clp.h);

	vrender_inf = caml_alloc_tuple(7);
	Store_field(vrender_inf, 0, vtid);
	Store_field(vrender_inf, 1, caml_copy_double(renderbuf.width));
	Store_field(vrender_inf, 2, caml_copy_double(renderbuf.height));
	Store_field(vrender_inf, 3, vclipping);
	Store_field(vrender_inf, 4, vkind);
	Store_field(vrender_inf, 5, Val_int(renderbuf.vp.x));
	Store_field(vrender_inf, 6, Val_int(renderbuf.vp.y));
	checkGLErrors("finish render to texture");

	vretval = caml_alloc_tuple(2);
	Store_field(vretval, 0, vrender_inf);
	Store_field(vretval, 1, Val_bool(dedicated));

	CAMLreturn(vretval);
}

value rendertex_create_byte(value *argv, int n) {
	return rendertex_create(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5]);
}

value rendertex_draw(value vclear, value vwidth, value vheight, value vrender_inf, value vdraw_func, value vdedicated) {
	PRINT_DEBUG("!!!rendertex_draw call");

	CAMLparam5(vclear, vwidth, vheight, vrender_inf, vdraw_func);
	CAMLxparam1(vdedicated);
	CAMLlocal1(vtmp);

	renderbuffer_t renderbuf;
	if (vdedicated == Val_true) RENDERBUF_OF_RENDERINF(renderbuf, vrender_inf, nextPOT)
	else RENDERBUF_OF_RENDERINF(renderbuf, vrender_inf, nextDBE)

	float new_w = Is_block(vwidth) ? Double_val(Field(vwidth, 0)) : renderbuf.width, new_h = Is_block(vheight) ? Double_val(Field(vheight, 0)) : renderbuf.height;
	color3F color;
	GLfloat alpha;

	if (vclear != Val_none) {
		vtmp = Field(vclear, 0);
		int icolor = Int_val(Field(vtmp, 0));
		color = COLOR3F_FROM_INT(icolor);
		alpha = Double_val(Field(vtmp, 1));
	}

	uint8_t resized = vdedicated == Val_true
		? rendertex_dedicated_draw(&renderbuf, vrender_inf, new_w, new_h, vclear != Val_none ? &color : NULL, alpha, vdraw_func)
		: rendertex_shared_draw(&renderbuf, vrender_inf, new_w, new_h, vclear != Val_none ? &color : NULL, alpha, vdraw_func);

	CAMLreturn(Val_bool(resized));
}

value rendertex_draw_byte(value *argv, int n) {
	return rendertex_draw(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5]);
}

value rendertex_save(value vrender_inf, value vpath) {
	CAMLparam1(vpath);

	renderbuffer_t renderbuf;
	RENDERBUF_OF_RENDERINF(renderbuf, vrender_inf, nextPOT); //nextPOT used for both dedicated and shared cause realWidth and realHeight are insignificant in this task
	uint8_t retval = renderbuf_save(&renderbuf, vpath, 0);

	CAMLreturn(Val_bool(retval));
}

value rendertex_data(value vrender_inf) {
	CAMLparam1(vrender_inf);
	CAMLlocal1(vbuf);

	renderbuffer_t renderbuf;
	RENDERBUF_OF_RENDERINF(renderbuf, vrender_inf, nextPOT); //nextPOT used for both dedicated and shared cause realWidth and realHeight are insignificant in this task

	viewport *vp = &renderbuf.vp;
	framebuf_push(renderbuf.fbid, vp, FRAMEBUF_APPLY_BUF);
	char *pixels = caml_stat_alloc(4 * vp->w * vp->h);
	glReadPixels(vp->x, vp->y, vp->w, vp->h, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

	intnat dims[2];
	dims[0] = vp->w;
	dims[1] = vp->h;
	vbuf = caml_ba_alloc(CAML_BA_MANAGED|CAML_BA_INT32, 2, pixels, dims);
	framebuf_pop();

	CAMLreturn(vbuf);
}

value rendertex_release(value vrender_inf) {
	CAMLparam1(vrender_inf);
	rendertex_shared_release(vrender_inf);
	CAMLreturn(Val_unit);
}
