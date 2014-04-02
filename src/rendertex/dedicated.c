#include <math.h>
#include "common.h"
#include "dedicated.h"

#define MAX_RENDERTEX_NUM 100

static unsigned int rendertex_mem = 0;
static unsigned int rendertex_num = 0;

static void rendertex_finalize(value vtid) {
	struct tex *t = TEX(vtid);

	if (t) {
		framebuf_return_id(t->fbid, t->tid);
		resetTextureIfBounded(t->tid);
		checkGLErrors("finalize texture");

		rendertex_mem -= t->mem;
		--rendertex_num;
		caml_free_dependent_memory(t->mem);
	};
}

static int rendertex_compare(value vtid_a, value vtid_b) {
	GLuint tid_a = TEX(vtid_a)->tid;
	GLuint tid_b = TEX(vtid_b)->tid;
	if (tid_a == tid_b) return 0;
	else {
		if (tid_a < tid_b) return -1;
		return 1;
	}
}

static struct custom_operations rendetex_opts = {
  "pointer to dedicated render texture id",
  rendertex_finalize,
  rendertex_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value caml_gc_major(value v);

void rendertex_dedicated_clear(color3F *color, GLfloat alpha) {
	PRINT_DEBUG("rendertex_dedicated_clear call %f %f %f %f", color->r, color->g, color->b, alpha);

	glClearColor(color->r, color->g, color->b, alpha);
	glClear(GL_COLOR_BUFFER_BIT);	
}

void rendertex_dedicated_create(renderbuffer_t *renderbuf, uint16_t w, uint16_t h, GLuint filter, color3F *color, GLfloat alpha, value draw_func, value *tex_id) {
	PRINT_DEBUG("rendertex_dedicated_create call");

	GLuint texw = (GLuint)nextPOT(w);
	GLuint texh = (GLuint)nextPOT(h);
	int tex_data_size = texw * texh * 4;
	GLuint x = (texw - w) / 2;
	GLuint y = (texh - h) / 2;

	PRINT_DEBUG("w %d, h %d, texw %d, texh %d, x %d, y %d", w, h, texw, texh, x, y);

	renderbuf->width = w;
	renderbuf->height = h;
	renderbuf->realWidth = texw;
	renderbuf->realHeight = texh;
	renderbuf->vp = (viewport){ x, y, w, h };
	renderbuf->clp = (clipping){ (double)x / (double)texw, (double)y / (double)texh, w / (double)texw, h / (double)texh };

	PRINT_DEBUG("viewport %d %d %d %d", renderbuf->vp.x, renderbuf->vp.y, renderbuf->vp.w, renderbuf->vp.h);
	PRINT_DEBUG("clipping %f %f %f %f", renderbuf->clp.x, renderbuf->clp.y, renderbuf->clp.w, renderbuf->clp.h);

	framebuf_get_id(&renderbuf->fbid, &renderbuf->tid, texw, texh, filter);
	framebuf_push(renderbuf->fbid, &renderbuf->vp, FRAMEBUF_APPLY_ALL);
	lgResetBoundTextures();
	renderbuf_activate(renderbuf);
	rendertex_dedicated_clear(color, alpha);
	caml_callback(draw_func, (value)renderbuf);
	renderbuf_deactivate();
	framebuf_pop();

	if (++rendertex_num >= MAX_RENDERTEX_NUM) caml_gc_major(0);
	caml_alloc_dependent_memory(tex_data_size);
	*tex_id = caml_alloc_custom(&rendetex_opts, sizeof(struct tex), tex_data_size, MAX_GC_MEM);

	struct tex *t = TEX(*tex_id);
	t->fbid = renderbuf->fbid;
	t->tid = renderbuf->tid;
	t->mem = tex_data_size;
	rendertex_mem += tex_data_size;
}

uint8_t rendertex_dedicated_draw(renderbuffer_t *renderbuf, value render_inf, float new_w, float new_h, color3F *color, GLfloat alpha, value draw_func) {
	CAMLparam2(render_inf, draw_func);
	CAMLlocal2(vtmp, new_clipping);

	uint8_t resized = 0;
	float new_real_w = nextPOT(ceil(new_w)), new_real_h = nextPOT(ceil(new_h));

	PRINT_DEBUG("%f; %f ||| %f, %f", new_w, renderbuf->width, new_h, renderbuf->height);

	if (new_w != renderbuf->width || new_h != renderbuf->height) {
		resized = 1;

		if (new_real_w != renderbuf->realWidth || new_real_h != renderbuf->realHeight) {
			lgGLBindTexture(renderbuf->tid, 1);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, new_real_w, new_real_h, 0, GL_RGBA,GL_UNSIGNED_BYTE, NULL);
			update_texture_id_size(Field(render_inf, 0), new_real_w * new_real_h * 4);
			checkGLErrors("dedicated rendertex resize");
		}

		if (new_real_w == new_w && new_real_h == new_h) {
			renderbuf->vp = (viewport){ 0., 0., new_w, new_h };
			renderbuf->clp = (clipping){ 0., 0., 1., 1. };
			new_clipping = Val_none;
		} else {
			renderbuf->vp = (viewport){ (GLuint)(new_real_w - ceil(new_w)) / 2, (GLuint)(new_real_h - ceil(new_h)) / 2, (GLuint)new_w, (GLuint)new_h };
			renderbuf->clp = (clipping){
				(double)renderbuf->vp.x / new_real_w,
				(double)renderbuf->vp.y / new_real_h,
				(new_w / new_real_w),
				(new_h / new_real_h)
			};

			vtmp = caml_alloc(4 * Double_wosize, Double_array_tag);
			Store_double_field(vtmp, 0, renderbuf->clp.x);
			Store_double_field(vtmp, 1, renderbuf->clp.y);
			Store_double_field(vtmp, 2, renderbuf->clp.w);
			Store_double_field(vtmp, 3, renderbuf->clp.h);
			new_clipping = caml_alloc_tuple(1);
			Store_field(new_clipping, 0, vtmp);
		};

		Store_field(render_inf, 1, caml_copy_double(new_w));
		Store_field(render_inf, 2, caml_copy_double(new_h));
		Store_field(render_inf, 3, new_clipping);
		Store_field(render_inf, 5, Val_int(renderbuf->vp.x));
		Store_field(render_inf, 6, Val_int(renderbuf->vp.y));
	}

	framebuf_push(renderbuf->fbid, &renderbuf->vp, FRAMEBUF_APPLY_ALL);
	renderbuf_activate(renderbuf);

	if (color) {
		rendertex_dedicated_clear(color, alpha);
	}

	caml_callback(draw_func, (value)renderbuf);

	renderbuf_deactivate();
	framebuf_pop();

	CAMLreturn(resized);
}
