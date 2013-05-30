#include "mlwrapper_android.h"

static jobject activity;

#define GET_ENV													\
	JNIEnv *env;												\
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);

#define GET_ACTIVITY																									\
	if (!activity) {																									\
		jclass activityCls = (*env)->FindClass(env, "ru/redspell/lightning/LightActivity");								\
		jfieldID fid = (*env)->GetStaticFieldID(env, activityCls, "instance", "Lru/redspell/lightning/LightActivity;");	\
		jobject tmp = (*env)->GetStaticObjectField(env, activityCls, fid);												\
		activity = (*env)->NewGlobalRef(env, tmp);																		\
		(*env)->DeleteLocalRef(env, activityCls);																		\
		(*env)->DeleteLocalRef(env, tmp);																				\
	}

#define MAKE_JAVA_STRING(val, jstr)									\
	{																\
		if (jstr) (*env)->DeleteGlobalRef(env, jstr);				\
		jstring tmp = (*env)->NewStringUTF(env, String_val(val));	\
		jstr = (*env)->NewGlobalRef(env, tmp);						\
		(*env)->DeleteLocalRef(env, tmp);							\
	}
