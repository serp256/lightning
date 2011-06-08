
#include <stdio.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include "mlwrapper.h"

#define NIL Val_int(0)


#define ERROR(fmt,args...) fprintf(stderr,fmt, ## args)

#ifdef DEBUG
    #define PRINT_DEBUG(fmt,args...)  (fprintf(stderr,fmt, ## args),putc('\n',stderr))
#else
    #define PRINT_DEBUG(fmt,args...)
#endif


mlstage *mlstage_create(float width,float height) {
	PRINT_DEBUG("mlstage_create");
	mlstage *stage = malloc(sizeof(mlstage));
	value *create_ml_stage = (value*)caml_named_value("stage_create");
	if (create_ml_stage == NULL) {
		ERROR("ocaml not initialized\n");
		return NULL;
	};
	stage->width = width;
	stage->height = height;
	stage->stage = caml_callback2(*create_ml_stage,caml_copy_double(width),caml_copy_double(height));
	caml_register_global_root(&stage->stage);
    PRINT_DEBUG("stage successfully created");
	return stage;
}

void mlstage_destroy(mlstage *mlstage) {
	caml_remove_global_root(&mlstage->stage);
	caml_gc_compaction(Val_int(0));
	free(mlstage);
}

static value advanceTime_method = NIL;
void mlstage_advanceTime(mlstage *mlstage,double timePassed) {
	if (advanceTime_method == NIL)
		advanceTime_method = caml_hash_variant("advanceTime");
	caml_callback2(caml_get_public_method(mlstage->stage,advanceTime_method),mlstage->stage,caml_copy_double(timePassed));
}



/*
void mlrender_clearTexture() {
    static value *clearTexture;
    if (clearTexture == NULL)
        clearTexture = caml_named_value("clear_texture");
    caml_callback(*clearTexture,Val_int(0));
}*/

static value render_method = NIL;
void mlstage_render(mlstage *mlstage) {
	// вызвать у stage метод который рендерит чего-то
	if (render_method == NIL)
		render_method = caml_hash_variant("render");
	caml_callback2(caml_get_public_method(mlstage->stage,render_method),mlstage->stage,Val_int(0));
}


static value processTouches_method = NIL;

void mlstage_processTouches(mlstage *mlstage, value touches) {
    PRINT_DEBUG("mlstage_processTouches");
    CAMLparam1(touches);
	// вызвать у stage метод который процессит тачи
	if (processTouches_method == NIL) 
		processTouches_method = caml_hash_variant("processTouches");
	caml_callback2(caml_get_public_method(mlstage->stage,processTouches_method),mlstage->stage,touches);
	CAMLreturn0;
}


/*
static value *mltouch_create_callback = NULL;

value mltouch_create(double timestamp,float globalX,float globalY,float previousGlobalX,float previousGlobalY,int tapCount, SPTouchPhase phase) {
	CAMLparam0();
	CAMLlocalN(params,7);
	CAMLlocal1(touch);
	if (mltouch_create_callback == NULL) {
		mltouch_create_callback = (value*)caml_named_value("touch_create");
		if (mltouch_create_callback == NULL) {
			ERROR("can't registred ml create_touch\n");
			return (value)NULL;
		}
	}
	params[0] = caml_copy_double(timestamp);
	params[1] = caml_copy_double(globalX);
	params[2] = caml_copy_double(globalY);
	params[3] = caml_copy_double(previousGlobalX);
	params[4] = caml_copy_double(previousGlobalY);
	params[5] = Val_int(tapCount);
	params[6] = Val_int(phase);
	touch = caml_callbackN(*mltouch_create_callback,7,params);
	CAMLreturn(touch);
}
*/
