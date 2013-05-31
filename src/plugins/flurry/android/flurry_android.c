#include "plugin_common.h"

static jstring appId = NULL;
static jclass flurryAgentCls = NULL;

#define GET_FLURRY_AGENT														\
	if (!flurryAgentCls) {														\
		jclass tmp = (*env)->FindClass(env, "com/flurry/android/FlurryAgent");	\
		flurryAgentCls = (*env)->NewGlobalRef(env, tmp);						\
		(*env)->DeleteLocalRef(env, tmp);										\
	}

void ml_flurryInit(value v_appId) {
	GET_ENV;
	MAKE_GLOB_JAVA_STRING(v_appId, appId);
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
