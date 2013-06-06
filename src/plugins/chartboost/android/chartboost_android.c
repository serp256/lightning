#include "plugin_common.h"

static jclass chartboostCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(chartboostCls,ru/redspell/lightning/plugins/LightChartboost);

void ml_chartBoostStartSession(value v_appId, value v_appSig) {
	static int started = 0;
	if (started) return;

	GET_ENV;
	GET_CLS;

	jstring j_appId = (*env)->NewStringUTF(env, String_val(v_appId));
	jstring j_appSig = (*env)->NewStringUTF(env, String_val(v_appSig));

	jmethodID mid = (*env)->GetStaticMethodID(env, chartboostCls, "startSession", "(Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, chartboostCls, mid, j_appId, j_appSig);
	(*env)->DeleteLocalRef(env, j_appId);
	(*env)->DeleteLocalRef(env, j_appSig);

	started = 1;
}
