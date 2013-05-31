#include "plugin_common.h"

static jclass chartboostCls = NULL;

#define GET_CHARTBOOST																			\
	if (!chartboostCls) {																		\
		jclass tmp = (*env)->FindClass(env, "ru/redspell/lightning/plugins/LightChartboost");	\
		chartboostCls = (*env)->NewGlobalRef(env, tmp);											\
		(*env)->DeleteLocalRef(env, tmp);														\
	}

void ml_chartBoostInit(value v_appId, value v_appSig) {
	GET_ENV;
	GET_CHARTBOOST;

	jstring j_appId = (*env)->NewStringUTF(env, String_val(v_appId));
	jstring j_appSig = (*env)->NewStringUTF(env, String_val(v_appSig));

	jmethodID mid = (*env)->GetStaticMethodID(env, chartboostCls, "init", "(Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, chartboostCls, mid, j_appId, j_appSig);
}

void ml_chartBoostStartSession() {
	GET_ENV;
	GET_CHARTBOOST;

	jmethodID mid = (*env)->GetStaticMethodID(env, chartboostCls, "startSession", "()V");
	(*env)->CallStaticVoidMethod(env, chartboostCls, mid);
}