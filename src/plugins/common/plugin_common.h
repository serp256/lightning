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

#define JString_val(jstr,val) jstring jstr = (*env)->NewStringUTF(env, String_val(val));
#define JString_optval(jstr,val) jstring jstr = Is_block(val) ? (*env)->NewStringUTF(env, String_val(Field(val,0))) : NULL;

#define STATIC_MID(cls, name, sig) static jmethodID mid = 0; if (!mid) mid = (*env)->GetStaticMethodID(env, cls, #name, sig);