#include "mlwrapper_android.h"

static jstring appId = NULL;
static jclass flurryAgentCls = NULL;
static jobject activity = NULL;

#define GET_ENV													\
	JNIEnv *env;												\
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);

#define GET_FLURRY_AGENT														\
	if (!flurryAgentCls) {														\
		jclass tmp = (*env)->FindClass(env, "com/flurry/android/FlurryAgent");	\
		flurryAgentCls = (*env)->NewGlobalRef(env, tmp);						\
		(*env)->DeleteLocalRef(env, tmp);										\
	}

#define GET_ACTIVITY																									\
	if (!activity) {																									\
		jclass activityCls = (*env)->FindClass(env, "ru/redspell/lightning/LightActivity");								\
		jfieldID fid = (*env)->GetStaticFieldID(env, activityCls, "instance", "Lru/redspell/lightning/LightActivity;");	\
		jobject tmp = (*env)->GetStaticObjectField(env, activityCls, fid);												\
		activity = (*env)->NewGlobalRef(env, tmp);																		\
		(*env)->DeleteLocalRef(env, activityCls);																		\
		(*env)->DeleteLocalRef(env, tmp);																				\
	}

void ml_flurryInit(value v_appId) {
	GET_ENV;

	if (appId) (*env)->DeleteGlobalRef(env, appId);
	jstring tmp = (*env)->NewStringUTF(env, String_val(v_appId));

	appId = (*env)->NewGlobalRef(env, tmp);
	(*env)->DeleteLocalRef(env, tmp);
}

void ml_flurryStartSession() {
	if (!appId) caml_failwith("call Flurry.init with app id before starting session");

	GET_ENV;
	GET_FLURRY_AGENT;
	GET_ACTIVITY;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, flurryAgentCls, "onStartSession", "(Landroid/content/Context;Ljava/lang/String;)V");

	(*env)->CallStaticVoidMethod(env, flurryAgentCls, mid, activity, appId);
}

void ml_flurryEndSession() {
	GET_ENV;
	GET_FLURRY_AGENT;
	GET_ACTIVITY;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, flurryAgentCls, "onEndSession", "(Landroid/content/Context;)V");

	(*env)->CallStaticVoidMethod(env, flurryAgentCls, mid, activity);
}
