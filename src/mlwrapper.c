
#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include "light_common.h"
#include "mlwrapper.h"


#define NIL Val_int(0)

extern void caml_gc_compaction();


#ifdef ANDROID
#define caml_acquire_runtime_system()
#define caml_release_runtime_system()
#else
#include <caml/threads.h>
#endif


mlstage *mlstage_create(float width,float height) {
	//PRINT_DEBUG("mlstage_create: %d",(unsigned int)pthread_self());
	//caml_c_thread_register();
	//caml_acquire_runtime_system();
	mlstage *stage = malloc(sizeof(mlstage));
	value *create_ml_stage = (value*)caml_named_value("stage_create");
	if (create_ml_stage == NULL) {
		ERROR("ocaml not initialized\n");
		return NULL;
	};
	PRINT_DEBUG("create stage with size: %f:%f",width,height);
	stage->width = width;
	stage->height = height;
	caml_acquire_runtime_system();
	stage->stage = caml_callback2(*create_ml_stage,caml_copy_double(width),caml_copy_double(height));// FIXME: GC 
	stage->needCancelAllTouches = 0;
	caml_register_generational_global_root(&stage->stage);
	caml_release_runtime_system();
	PRINT_DEBUG("stage successfully created");
	return stage;
}


void mlstage_resize(mlstage *mlstage,float width,float height) {
	printf("stage: %ld,w=%f,h=%f\n",mlstage->stage,width,height);
	mlstage->width = width;
	mlstage->height = height;
	caml_acquire_runtime_system();
	value w = Val_unit, h = Val_unit;
	Begin_roots2(w,h);
	w = caml_copy_double(width);
	h = caml_copy_double(height);
	value resize = caml_get_public_method(mlstage->stage,caml_hash_variant("resize"));
	caml_callback3(resize,mlstage->stage,w,h);
	End_roots();
	caml_release_runtime_system();
}


void mlstage_destroy(mlstage *mlstage) {
	caml_acquire_runtime_system();
	caml_remove_generational_global_root(&mlstage->stage);
	caml_gc_compaction(Val_int(0));
	caml_release_runtime_system();
	free(mlstage);
}

static value advanceTime_method = NIL;

void mlstage_advanceTime(mlstage *mlstage,double timePassed) {
	//caml_acquire_runtime_system();
	if (advanceTime_method == NIL) advanceTime_method = caml_hash_variant("advanceTime");
	value dt = caml_copy_double(timePassed);
	value advanceTimeMethod = caml_get_public_method(mlstage->stage,advanceTime_method);
	caml_callback2(advanceTimeMethod,mlstage->stage,dt);
	//caml_release_runtime_system();
}

static value render_method = NIL;

void mlstage_render(mlstage *mlstage) {
	PRINT_DEBUG("mlstage render");
	//caml_acquire_runtime_system();
	if (render_method == NIL)
		render_method = caml_hash_variant("renderStage");
	caml_callback2(caml_get_public_method(mlstage->stage,render_method),mlstage->stage,Val_unit);
	//caml_release_runtime_system();
}

static value *preRender_fun = NULL;
void mlstage_preRender() {
	//caml_acquire_runtime_system();
	if (preRender_fun == NULL) preRender_fun = (value*)caml_named_value("prerender");
	caml_callback(*preRender_fun,Val_unit);
	//caml_release_runtime_system();
}

void mlstage_background() {
	static value *on_background_fun = NULL;
	if (on_background_fun == NULL) on_background_fun = caml_named_value("on_background");
	caml_callback(*on_background_fun,Val_unit);
}

void mlstage_foreground(mlstage *mlstage) {
	static value *on_foreground_fun = NULL;
	if (on_foreground_fun == NULL) on_foreground_fun = caml_named_value("on_foreground");
	caml_callback(*on_foreground_fun,Val_unit);
}

static value processTouches_method = NIL;

void mlstage_processTouches(mlstage *mlstage, value touches) {
	PRINT_DEBUG("mlstage_processTouches");
	if (processTouches_method == NIL) processTouches_method = caml_hash_variant("processTouches");
	caml_callback2(caml_get_public_method(mlstage->stage,processTouches_method),mlstage->stage,touches);
}

static value cancelAllTouches_method = NIL;

void mlstage_cancelAllTouches(mlstage *mlstage) {
	PRINT_DEBUG("mlstage cancelAllTouches");
	if (cancelAllTouches_method == NIL) cancelAllTouches_method = caml_hash_variant("cancelAllTouches");
	caml_callback2(caml_get_public_method(mlstage->stage,cancelAllTouches_method),mlstage->stage,Val_unit);
}


void ml_memoryWarning() {
	caml_acquire_runtime_system();
	caml_gc_compaction();
	caml_release_runtime_system();
}
