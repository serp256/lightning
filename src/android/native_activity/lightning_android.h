#ifndef LIGHTNING_ANDROID_H
#define LIGHTNING_ANDROID_H

#include <light_common.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>

typedef void (*lightning_onmlthreadfunc_t)(void *data);

typedef struct {
	lightning_onmlthreadfunc_t func;
	void *data;
} lightning_onmlthread_t;

enum {
	LIGTNING_CMD_RUN_ON_ML_THREAD = 100
};

void	lightning_init			();
char*	lightning_get_locale	();
jclass	lightning_find_class	(const char *); /* use this functions rather than FIND_CLASS macro from engine.h */
void 	lightning_runonmlthread	(lightning_onmlthreadfunc_t, void *);

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *, jclass);

#endif