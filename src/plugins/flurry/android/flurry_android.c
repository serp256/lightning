#include "plugin_common.h"

// static jstring appId = NULL;
static int started = 0;
static jclass flurryAgentCls = NULL;

#define GET_FLURRY_AGENT														\
	if (!flurryAgentCls) {														\
		jclass tmp = (*env)->FindClass(env, "com/flurry/android/FlurryAgent");	\
		flurryAgentCls = (*env)->NewGlobalRef(env, tmp);						\
		(*env)->DeleteLocalRef(env, tmp);										\
	}

void ml_flurryStartSession(value v_appId) {
	if (started) return;

	GET_ENV;
	GET_FLURRY_AGENT;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, flurryAgentCls, "onStartSession", "(Landroid/content/Context;Ljava/lang/String;)V");

	jstring j_appId = (*env)->NewStringUTF(env, String_val(v_appId));
	(*env)->CallStaticVoidMethod(env, flurryAgentCls, mid, jActivity, j_appId);
	(*env)->DeleteLocalRef(env, j_appId);
	started = 1;
}

void ml_flurryEndSession() {
	GET_ENV;
	GET_FLURRY_AGENT;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, flurryAgentCls, "onEndSession", "(Landroid/content/Context;)V");

	(*env)->CallStaticVoidMethod(env, flurryAgentCls, mid, jActivity);
	started = 0;
}
