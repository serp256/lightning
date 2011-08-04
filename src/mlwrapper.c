
#include <stdio.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include "mlwrapper.h"

#define NIL Val_int(0)


#define ERROR(fmt,args...) fprintf(stderr,fmt, ## args)

#ifdef DEBUG
    #define PRINT_DEBUG(fmt,args...)  (fprintf(stderr,fmt, ## args),putc('\n',stderr))
#else
    #define PRINT_DEBUG(fmt,args...)
#endif


#ifdef ANDROID
#define caml_acquire_runtime_system()
#define caml_release_runtime_system()
#else
#include <caml/threads.h>
#endif


mlstage *mlstage_create(float width,float height) {
	PRINT_DEBUG("mlstage_create: %d",(unsigned int)pthread_self());
	//caml_c_thread_register();
	//caml_acquire_runtime_system();
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
	caml_release_runtime_system();
	PRINT_DEBUG("stage successfully created");
	return stage;
}

void mlstage_destroy(mlstage *mlstage) {
	caml_acquire_runtime_system();
	caml_remove_global_root(&mlstage->stage);
	caml_gc_compaction(Val_int(0));
	caml_release_runtime_system();
	free(mlstage);
}

static value advanceTime_method = NIL;
void mlstage_advanceTime(mlstage *mlstage,double timePassed) {
	PRINT_DEBUG("advance time: %d",(unsigned int)pthread_self());
	caml_acquire_runtime_system();
	if (advanceTime_method == NIL)
		advanceTime_method = caml_hash_variant("advanceTime");
	caml_callback2(caml_get_public_method(mlstage->stage,advanceTime_method),mlstage->stage,caml_copy_double(timePassed));
	caml_release_runtime_system();
}

static value render_method = NIL;
void mlstage_render(mlstage *mlstage) {
	PRINT_DEBUG("mlstage render");
	caml_acquire_runtime_system();
	if (render_method == NIL)
		render_method = caml_hash_variant("render");
	caml_callback2(caml_get_public_method(mlstage->stage,render_method),mlstage->stage,Val_int(0));
	caml_release_runtime_system();
}


static value processTouches_method = NIL;

void mlstage_processTouches(mlstage *mlstage, value touches) {
	PRINT_DEBUG("mlstage_processTouches");
	if (processTouches_method == NIL) processTouches_method = caml_hash_variant("processTouches");
	caml_callback2(caml_get_public_method(mlstage->stage,processTouches_method),mlstage->stage,touches);
}
