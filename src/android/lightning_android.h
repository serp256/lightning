#ifndef LIGHTNING_ANDROID_H
#define LIGHTNING_ANDROID_H

#define VAL_TO_JSTRING(vstr, jstr) jstr = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(vstr));
#define JSTRING_TO_VAL(jstr, vstr) { const char *cstr = (*ML_ENV)->GetStringUTFChars(ML_ENV, jstr, JNI_FALSE); vstr = caml_copy_string(cstr); (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jstr, cstr); }

#include <light_common.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

#ifdef SILENT
#define DEBUG(str) 
#define DEBUGF(fmt,args...) 
#else
#define DEBUG(str) __android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING",str)
#define DEBUGF(fmt,args...) __android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING",fmt, ## args)
#endif

#define NILL Val_int(0)
#define NONE Val_int(0)

extern jclass lightning_cls;

void	lightning_init			();
char*	lightning_get_locale	();

int getResourceFd(const char *path, resource *res);

#endif