#include "shared.h"
#include "rects-bin.h"
#include "inline_shaders.h"

typedef struct {
	rbin_t bin;
	value vtid;
} sharedtex_t;

static int tex_num = 0;
static sharedtex_t *texs = NULL;

static struct custom_operations sharedtex_ops = {
  "fr.inria.caml.curses_windows",
  custom_finalize_default,
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
	pnt_t pnt = (pnt_t) { renderbuf->vp.x, renderbuf->vp.y };
	int i;
	struct tex *t;

	for (i = 0; i < tex_num; i++) {
		t = TEX(texs[i].vtid);

		if (t->fbid == renderbuf->fbid && t->tid == renderbuf->tid) {
			rbin_rm_rect(&texs[i].bin, &pnt);
			break;
		}
	}
}

static sharedtex_t *rendertex_shared_get_rect(renderbuffer_t *renderbuf, uint16_t w, uint16_t h) {
	int i = 0;
	pnt_t pnt;
	sharedtex_t *tex;
	
	GLuint tex_size = renderbuf_shared_tex_size();
	GLuint w_adjustment = 8 - w % 8;
	GLuint h_adjustment = 8 - h % 8;
	GLuint rectw = w + w_adjustment;
	GLuint recth = h + h_adjustment;

	// try reuse
	for (i = 0; i < tex_num; i++) {
		if (rbin_reuse_rect(&texs[i].bin, rectw, recth, &pnt)) {
			tex = texs + i;
			goto FINDED;
		}
	};
	// try add
	uint8_t repair_indx = 0;
	for (i = 0; i < tex_num; i++) {
		if (!rbin_need_repair(&(texs[i].bin))) {
			if (rbin_add_rect(&texs[i].bin, rectw, recth, &pnt)) {
				tex = texs + i;
				goto FINDED;
			}
		} else {
			sharedtex_t tmp = texs[repair_indx];
			texs[repair_indx++] = texs[i];
			texs[i] = tmp;
		}
	};
	// try repair
	if (repair_indx > 3) repair_indx = 3;
	for (i = 0; i < repair_indx; i++) {
		rbin_repair(&texs[i].bin);
		if (rbin_add_rect(&texs[i].bin, rectw, recth, &pnt)) {
			tex = texs + i;
			goto FINDED;
		}
	};
	// alloc new 

	tex_num++;
	texs = realloc(texs,sizeof(sharedtex_t) * tex_num);
	tex = texs + tex_num - 1;

	tex->vtid = caml_alloc_custom(&sharedtex_ops, sizeof(struct tex), 0, 1);
	rbin_init(&tex->bin, tex_size, tex_size);
	caml_register_generational_global_root(&tex->vtid);

	struct tex *t = TEX(tex->vtid);
	t->fbid = framebuf_get_id();
	t->tid = tex_get_id();
	t->mem = tex_size * tex_size * 4;	

	glBindTexture(GL_TEXTURE_2D, t->tid);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, tex_size, tex_size, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

	glBindFramebuffer(GL_FRAMEBUFFER, t->fbid);
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, t->tid, 0);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return 0;

	if (!rbin_add_rect(&tex->bin, rectw, recth, &pnt)) return 0;
FINDED:
	renderbuf->fbid = t->fbid;
	renderbuf->tid = t->tid;
	renderbuf->width = w;
	renderbuf->height = h;
	renderbuf->realWidth = rectw;
	renderbuf->realHeight = recth;
	renderbuf->vp = (viewport){ (GLuint)pnt.x + w_adjustment / 2, (GLuint)pnt.y + h_adjustment  / 2, (GLuint)w, (GLuint)h };
	renderbuf->clp = (clipping){ (double)renderbuf->vp.x / (double)tex_size, (double)renderbuf->vp.y / (double)tex_size, w / (double)tex_size, h / (double)tex_size };

	return tex;
}

static void rendertex_shared_clear(color3F *color, GLfloat alpha) {
	glDisable(GL_BLEND);
	const prg_t* clear_progr = clear_quad_progr();
	lgGLEnableVertexAttribs(lgVertexAttribFlag_Position);
	static GLfloat vertices[8] = { -1., -1., 1., -1., -1., 1., 1., 1. };
	glUniform4f(clear_progr->uniforms[0], color->r, color->g, color->b, alpha);
 	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void rendertex_shared_create(renderbuffer_t *renderbuf, uint16_t w, uint16_t h, GLuint filter, color3F *color, GLfloat alpha, value draw_func, value *tex_id) {
	sharedtex_t *tex = rendertex_shared_get_rect(renderbuf, w, h);
	if (!tex) {
		caml_failwith("cannot get fresh rect for shared tex");
	}

	viewport* vp = &renderbuf->vp;
	framebuf_push(renderbuf->fbid, vp, FRAMEBUF_APPLY_BUF); //only framebuffer binding, cause shared textures has untypical cleaning viewport. setting viewport manually 
	glViewport(vp->x - (renderbuf->realWidth - vp->w) / 2, vp->y - (renderbuf->realHeight - vp->h) / 2, renderbuf->realWidth, renderbuf->realHeight);

	lgResetBoundTextures();
	renderbuf_activate(renderbuf);

	rendertex_shared_clear(color, alpha);
	glViewport(vp->x, vp->y, vp->w, vp->h);
	caml_callback(draw_func, (value)renderbuf);

	renderbuf_deactivate();
	framebuf_pop();

	*tex_id = tex->vtid;
}

uint8_t rendertex_shared_draw(renderbuffer_t *renderbuf, value render_inf, float new_w, float new_h, color3F *color, GLfloat alpha, value draw_func) {
	CAMLparam2(render_inf, draw_func);
	CAMLlocal2(vtmp, new_clipping);

	uint8_t resized = 0;

	if (new_w != renderbuf->width || new_h != renderbuf->height) {
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
