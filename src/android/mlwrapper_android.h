
#ifndef __MLWRAPPER_ANDROID_H__
#define __MLWRAPPER_ANDROID_H__

#include <jni.h>
#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include <caml/fail.h>

#include "light_common.h"
#include "mlwrapper.h"

#ifdef SILENT
#define DEBUG(str) 
#define DEBUGF(fmt,args...) 
#else
#define DEBUG(str) __android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING",str)
#define DEBUGF(fmt,args...) __android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING",fmt, ## args)
#endif

#define NILL Val_int(0)
#define NONE Val_int(0)

extern JavaVM *gJavaVM;
extern jobject jActivity;
extern jobject jView;
extern jclass jViewCls;
extern mlstage *stage;

jobject jApplicationContext(JNIEnv *env);

int getResourceFd(const char *path, resource *res);

//void ml_paymentsTest();
value ml_openURL(value url);
//void ml_setAssetsDir(value vassDir);
// char* get_locale();

#endif
