#include <math.h>
#include "shared.h"
#include "rects-bin.h"
#include "inline_shaders.h"

static uint8_t shared_tex_id = 0;

typedef struct {
	uint8_t id;
	rbin_t bin;
	value vtid;
} sharedtex_t;

static int tex_num = 0;
static sharedtex_t **texs = NULL;

static void finalize(value vtid) {
	PRINT_DEBUG("!!!!!!!!!!SHARED FINALIZE !!!!!!!!");
}

static struct custom_operations sharedtex_ops = {
  "shared rendertex",
  finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

GLuint renderbuf_shared_tex_size() {
    static GLint size = 0;
    if (!size) {
#ifdef PC
		size = 512;
#else
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, &size);
		size = size / 4;
#endif
    }
    return size;
}

static void rendertex_shared_return_rect(renderbuffer_t *renderbuf) {
	viewport *vp = &renderbuf->vp;
	pnt_t pnt = (pnt_t) { vp->x - (renderbuf->realWidth - vp->w) / 2, vp->y  - (renderbuf->realHeight - vp->h) / 2 };
	int i;
	struct tex *t;

	for (i = 0; i < tex_num; i++) {
		t = TEX(texs[i]->vtid);

		if (t->fbid == renderbuf->fbid && t->tid == renderbuf->tid) {
			rbin_rm_rect(&texs[i]->bin, &pnt);
			break;
		}
	}
}

static sharedtex_t *rendertex_shared_get_rect(renderbuffer_t *renderbuf, uint16_t w, uint16_t h) {
	int i = 0;
	pnt_t pnt;
	sharedtex_t *shared_tex;
	struct tex *tex;
	
	GLuint tex_size = renderbuf_shared_tex_size();
	GLuint w_adjustment = 8 - w % 8;
	GLuint h_adjustment = 8 - h % 8;
	GLuint rectw = w + w_adjustment;
	GLuint recth = h + h_adjustment;

	PRINT_DEBUG("rendertex_shared_get_rect %d %d, rect %d %d", w, h, rectw, recth);

	// try reuse
	PRINT_DEBUG("trying reuse...");
	for (i = 0; i < tex_num; i++) {
		if (rbin_reuse_rect(&texs[i]->bin, rectw, recth, &pnt)) {
			shared_tex = texs[i];
			tex = TEX(shared_tex->vtid);
			PRINT_DEBUG("reuse");
			// PRINT_DEBUG("reuse %d, %d", (int)pnt.x, (int)pnt.y);
			goto FINDED;
		}
	};
	// try add
	PRINT_DEBUG("trying add...");
	uint8_t repair_indx = 0;
	for (i = 0; i < tex_num; i++) {
		if (!rbin_need_repair(&texs[i]->bin)) {
			if (rbin_add_rect(&texs[i]->bin, rectw, recth, &pnt)) {
				shared_tex = texs[i];
				tex = TEX(shared_tex->vtid);
				PRINT_DEBUG("add");
				goto FINDED;
			}
		} else {
			sharedtex_t *tmp = texs[repair_indx];
			texs[repair_indx++] = texs[i];
			texs[i] = tmp;
		}
	};
	// try repair
	PRINT_DEBUG("try repair...");
	if (repair_indx > 3) repair_indx = 3;
	for (i = 0; i < repair_indx; i++) {
		rbin_repair(&texs[i]->bin);
		if (rbin_add_rect(&texs[i]->bin, rectw, recth, &pnt)) {
			shared_tex = texs[i];
			tex = TEX(shared_tex->vtid);
			PRINT_DEBUG("repair");
			goto FINDED;
		}
	};
	// alloc new 

	texs = (sharedtex_t**)realloc(texs, sizeof(sharedtex_t*) * ++tex_num);
	texs[tex_num - 1] = (sharedtex_t*)malloc(sizeof(sharedtex_t));
	shared_tex = texs[tex_num - 1];

	shared_tex->id = shared_tex_id++;
	shared_tex->vtid = caml_alloc_custom(&sharedtex_ops, sizeof(struct tex), 0, 1);
	rbin_init(&shared_tex->bin, tex_size, tex_size);
	caml_register_generational_global_root(&shared_tex->vtid);

	tex = TEX(shared_tex->vtid);
	tex->mem = tex_size * tex_size * 4;
	framebuf_get_id(&tex->fbid, &tex->tid, tex_size, tex_size, GL_LINEAR);

	if (!rbin_add_rect(&shared_tex->bin, rectw, recth, &pnt)) return 0;
FINDED:
	PRINT_DEBUG("found position at %d %d, value %d id %d fb %d tid %d", pnt.x, pnt.y, shared_tex->vtid, shared_tex->id, tex->fbid, tex->tid);

	renderbuf->fbid = tex->fbid;
	renderbuf->tid = tex->tid;
	renderbuf->width = w;
	renderbuf->height = h;
	renderbuf->realWidth = rectw;
	renderbuf->realHeight = recth;
	renderbuf->vp = (viewport){ (GLuint)pnt.x + w_adjustment / 2, (GLuint)pnt.y + h_adjustment  / 2, (GLuint)w, (GLuint)h };
	renderbuf->clp = (clipping){ (double)renderbuf->vp.x / (double)tex_size, (double)renderbuf->vp.y / (double)tex_size, w / (double)tex_size, h / (double)tex_size };

	return shared_tex;
}

extern GLuint currentShaderProgram;

static void rendertex_shared_clear(color3F *color, GLfloat alpha) {
	glDisable(GL_BLEND);
	const prg_t* clear_progr = clear_quad_progr();
	lgGLEnableVertexAttribs(lgVertexAttribFlag_Position);
	static GLfloat vertices[8] = { -1., -1., 1., -1., -1., 1., 1., 1. };
	glUniform4f(clear_progr->uniforms[0], color->r, color->g, color->b, alpha);
 	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glUseProgram(0);
	currentShaderProgram = 0;
	glEnable(GL_BLEND);	
}

void rendertex_shared_create(renderbuffer_t *renderbuf, uint16_t w, uint16_t h, GLuint filter, color3F *color, GLfloat alpha, value draw_func, value *tex_id) {
	PRINT_DEBUG("rendertex_shared_create call");

	sharedtex_t *tex = rendertex_shared_get_rect(renderbuf, w, h);
	if (!tex) {
		caml_failwith("cannot get fresh rect for shared tex");
	}

	viewport* vp = &renderbuf->vp;
	framebuf_push(renderbuf->fbid, vp, FRAMEBUF_APPLY_BUF); //only framebuffer binding, cause shared textures has untypical cleaning viewport. setting viewport manually 
	glViewport(vp->x - (renderbuf->realWidth - vp->w) / 2, vp->y - (renderbuf->realHeight - vp->h) / 2, renderbuf->realWidth, renderbuf->realHeight);

	lgResetBoundTextures();
	renderbuf_activate(renderbuf);

	PRINT_DEBUG("cleaning...");
	rendertex_shared_clear(color, alpha);
	PRINT_DEBUG("setting viewport %d %d %d %d", vp->x, vp->y, vp->w, vp->h);
	glViewport(vp->x, vp->y, vp->w, vp->h);
	PRINT_DEBUG("drawing...");
	caml_callback(draw_func, (value)renderbuf);
	PRINT_DEBUG("done");

	renderbuf_deactivate();
	framebuf_pop();

	*tex_id = tex->vtid;
}

uint8_t rendertex_shared_draw(renderbuffer_t *renderbuf, value render_inf, float new_w, float new_h, color3F *color, GLfloat alpha, value draw_func) {
	PRINT_DEBUG("rendertex_shared_draw call");
	CAMLparam2(render_inf, draw_func);
	CAMLlocal2(vtmp, new_clipping);

	uint8_t resized = 0;

	PRINT_DEBUG("new_w %f; renderbuf->width %f; new_h %f; renderbuf->height %f", new_w, renderbuf->width, new_h, renderbuf->height);

	if (new_w != renderbuf->width || new_h != renderbuf->height) {
		PRINT_DEBUG("resized");
		resized = 1;

		rendertex_shared_return_rect(renderbuf);
		sharedtex_t *tex = rendertex_shared_get_rect(renderbuf, new_w, new_h);
		if (!tex) {
			caml_failwith("cannot get fresh rect for shared tex");
		}

		vtmp = caml_alloc(4 * Double_wosize,Double_array_tag);
		Store_double_field(vtmp, 0, renderbuf->clp.x);
		Store_double_field(vtmp, 1, renderbuf->clp.y);
		Store_double_field(vtmp, 2, renderbuf->clp.w);
		Store_double_field(vtmp, 3, renderbuf->clp.h);
		new_clipping = caml_alloc_small(1, 0);
		Store_field(new_clipping, 0, vtmp);

		Store_field(render_inf, 0, tex->vtid);
		Store_field(render_inf, 1, caml_copy_double(new_w));
		Store_field(render_inf, 2, caml_copy_double(new_h));
		Store_field(render_inf, 3, new_clipping);
		Store_field(render_inf, 5, Val_int(renderbuf->vp.x));
		Store_field(render_inf, 6, Val_int(renderbuf->vp.y));
	}

	viewport* vp = &renderbuf->vp;

	if (color) {
		framebuf_push(renderbuf->fbid, vp, FRAMEBUF_APPLY_BUF);
		glViewport(vp->x - (renderbuf->realWidth - vp->w) / 2, vp->y - (renderbuf->realHeight - vp->h) / 2, renderbuf->realWidth, renderbuf->realHeight);
		lgResetBoundTextures();
		renderbuf_activate(renderbuf);
		rendertex_shared_clear(color, alpha);
		glViewport(vp->x, vp->y, vp->w, vp->h);
	} else {
		framebuf_push(renderbuf->fbid, vp, FRAMEBUF_APPLY_ALL);
		lgResetBoundTextures();
		renderbuf_activate(renderbuf);
	}
		
	caml_callback(draw_func, (value)renderbuf);

	renderbuf_deactivate();
	framebuf_pop();

	CAMLreturn(resized);
}

void rendertex_shared_release(value render_inf) {
	PRINT_DEBUG("rendertex_shared_release");

	value tid = Field(render_inf, 0);
	int i;
	for (i = 0; i < tex_num; i++) {
		if (texs[i]->vtid == tid) {
			renderbuffer_t renderbuf;
			RENDERBUF_OF_RENDERINF(renderbuf, render_inf, nextDBE);
			pnt_t p = (pnt_t) { renderbuf.vp.x - (renderbuf.realWidth - renderbuf.vp.w) / 2, renderbuf.vp.y - (renderbuf.realHeight - renderbuf.vp.h) / 2 };
			rbin_rm_rect(&texs[i]->bin, &p);

			break;			
		}
	}	
}
