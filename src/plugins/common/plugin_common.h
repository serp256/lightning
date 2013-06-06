#include "mlwrapper_android.h"

#define GET_ENV													\
	JNIEnv *env;												\
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);

#define MAKE_GLOB_JAVA_STRING(val, jstr)							\
	{																\
		if (jstr) (*env)->DeleteGlobalRef(env, jstr);				\
		jstring tmp = (*env)->NewStringUTF(env, String_val(val));	\
		jstr = (*env)->NewGlobalRef(env, tmp);						\
		(*env)->DeleteLocalRef(env, tmp);							\
	}

#define GET_PLUGIN_CLASS(cls, classname)					\
	if (!cls) {												\
		jclass tmp = (*env)->FindClass(env, #classname);	\
		cls = (*env)->NewGlobalRef(env, tmp);				\
		(*env)->DeleteLocalRef(env, tmp);					\
	}