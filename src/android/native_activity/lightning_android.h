#ifndef LIGHTNING_ANDROID_H
#define LIGHTNING_ANDROID_H

#define VAL_TO_JSTRING(vstr, jstr) jurl = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(vurl));
#define JSTRING_TO_VAL(jstr, vstr) { const char *cstr = (*ML_ENV)->GetStringUTFChars(ML_ENV, jstr, JNI_FALSE); vstr = caml_copy_string(cstr); (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jstr, cstr); }

#include <light_common.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

extern jclass lightning_cls;

void	lightning_init					();
char*	lightning_get_locale			();

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *, jclass);

#endif