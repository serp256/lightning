#ifndef LIGHTNING_ANDROID_H
#define LIGHTNING_ANDROID_H

#define JSTRING_TO_VAL(jstr, vstr) { const char *cstr = (*ML_ENV)->GetStringUTFChars(ML_ENV, jstr, JNI_FALSE); vstr = caml_copy_string(cstr); (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jstr, cstr); }
#define RUN_ON_ML_THREAD(func, data) lightning_runonthread(LIGTNING_CMD_RUN_ON_ML_THREAD, func, data)
#define RUN_ON_MAIN_THREAD(func, data) lightning_runonthread(LIGTNING_CMD_RUN_ON_MAIN_THREAD, func, data)

#include <light_common.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

typedef void (*lightning_runnablefunc_t)(void *data);

typedef struct {
	lightning_runnablefunc_t func;
	void *data;
} lightning_runnable_t;

enum {
	LIGTNING_CMD_RUN_ON_ML_THREAD = 100,
	LIGTNING_CMD_RUN_ON_MAIN_THREAD
};

void	lightning_init			();
char*	lightning_get_locale	();
jclass	lightning_find_class	(const char *); /* use this functions rather than FIND_CLASS macro from engine.h */
void 	lightning_runonthread	(uint8_t, lightning_runnablefunc_t, void *);

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *, jclass);

#endif