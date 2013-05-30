#include "plugin_common.h"


void ml_chartBoostInit(value v_appId, value v_appSig) {
	GET_ENV;

	jstring appId = NULL;
	jstring appSig = NULL;

	static jclass chartboostCls = NULL;
	static jobject chartboost = NULL;

	if (!chartboostCls) {
		PRINT_DEBUG("_________________");
		jclass tmpCls = (*env)->FindClass(env, "com/chartboost/sdk/Chartboost");
		chartboostCls = (*env)->NewGlobalRef(env, tmpCls);
		(*env)->DeleteLocalRef(env, tmpCls);
		jmethodID mid = (*env)->GetStaticMethodID(env, chartboostCls, "sharedChartboost", "()Lcom/chartboost/sdk/Chartboost;");
		jobject tmpInstnc = (*env)->CallStaticObjectMethod(env, chartboostCls, mid);
		chartboost = (*env)->NewGlobalRef(env, tmpInstnc);
		(*env)->DeleteLocalRef(env, tmpInstnc);
		PRINT_DEBUG("_________________");
	}

	MAKE_JAVA_STRING(v_appId, appId);
	MAKE_JAVA_STRING(v_appSig, appSig);
}

void ml_chartBoostStartSession() {
	GET_ENV;

	// static jmethodID mid = 0;
	// if (!mid) mid = (*env)->GetMethodID(env, chartboostCls, "onCreate", "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;Lcom/chartboost/sdk/ChartboostDelegate;)V");
	// PRINT_DEBUG("!!!pizda2");

	// (*env)->CallVoidMethod(env, chartboost, mid, activity, appId, appSig, NULL);
	// PRINT_DEBUG("!!!pizda3");
}