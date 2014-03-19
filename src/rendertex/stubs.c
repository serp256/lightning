#include <math.h>
#include "common.h"
#include "dedicated.h"
#include "shared.h"

static void textureID_finalize(value textureID) {
/*	GLuint tid = TEXTURE_ID(textureID);
	if (tid) {
		PRINT_DEBUG("finalize render texture");
		back_texture_id(tid);
		resetTextureIfBounded(tid);
		checkGLErrors("finalize texture");
		struct tex *t = TEX(textureID);
		rendertex_mem -= t->mem;
		--rendertex_num;
		caml_free_dependent_memory(t->mem);
		LOGMEM("finalize",tid,t->mem);
	};*/
}

static int textureID_compare(value texid1,value texid2) {
/*	GLuint t1 = TEXTURE_ID(texid1);
	GLuint t2 = TEXTURE_ID(texid2);
	if (t1 == t2) return 0;
	else {
		if (t1 < t2) return -1;
		return 1;
	}*/
	return 0;
}

struct custom_operations rendertextureID_ops = {
  "pointer to render texture id",
  textureID_finalize,
  textureID_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value rendertex_create(value vkind, value vcolor, value valpha, value vwidth, value vheight, value vdraw_func) {
	PRINT_DEBUG("rendertex_create call");

	CAMLparam5(vkind, vcolor, valpha, vwidth, vheight);
	CAMLxparam1(vdraw_func);
	CAMLlocal4(vrender_inf, vtid, vtmp, vclipping);

	uint16_t w = ceil(Double_val(vwidth));
	uint16_t h = ceil(Double_val(vheight));
	GLuint tex_size = renderbuf_shared_tex_size();
	int8_t dedicated = (w > (tex_size / 2)) || (h > (tex_size / 2));
	GLuint filter = GL_LINEAR;

	PRINT_DEBUG("w %f, h %f, dedicated %d", w, h, dedicated);
	
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

	renderbuffer_t renderbuf;
	lgResetBoundTextures();

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

	vrender_inf = caml_alloc_tuple(7);
	Store_field(vrender_inf, 0, vtid);
	Store_field(vrender_inf, 1, caml_copy_double(renderbuf.width));
	Store_field(vrender_inf, 2, caml_copy_double(renderbuf.height));
	Store_field(vrender_inf, 3, vclipping);
	Store_field(vrender_inf, 4, vkind);
	Store_field(vrender_inf, 5, Val_int(renderbuf.vp.x));
	Store_field(vrender_inf, 6, Val_int(renderbuf.vp.y));
	checkGLErrors("finish render to texture");

	CAMLreturn(vrender_inf);
}

value rendertex_create_byte(value *argv, int n) {
	return rendertex_create(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5]);
}

value rendertex_draw(value vclear, value vwidth, value vheight, value vrender_inf, value vdraw_func, value vdedicated) {
	CAMLparam5(vclear, vwidth, vheight, vrender_inf, vdraw_func);
	CAMLxparam1(vdedicated);
	CAMLlocal1(vtmp);

	renderbuffer_t renderbuf;
	RENDERBUF_OF_RENDERINF(renderbuf, vrender_inf, nextPOT); //fix!!! for shared should be nextDBE

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

value ml_renderbuffer_data(value vrender_inf) {
	CAMLparam1(vrender_inf);
	CAMLreturn(Val_unit);
}
