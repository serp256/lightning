#include "plugin_common.h"

static jclass appfloodCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(appfloodCls,ru/redspell/lightning/plugins/LightAppflood);

void ml_appfloodInit(value v_appKey, value v_secKey) {
	GET_ENV;
	GET_CLS;

	jstring j_appKey = (*env)->NewStringUTF(env, String_val(v_appKey));
	jstring j_secKey = (*env)->NewStringUTF(env, String_val(v_secKey));

	jmethodID mid = (*env)->GetStaticMethodID(env, appfloodCls, "init", "(Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, appfloodCls, mid, j_appKey, j_secKey);

	(*env)->DeleteLocalRef(env, j_appKey);
	(*env)->DeleteLocalRef(env, j_secKey);	
}

void ml_appfloodStartSession() {
	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, appfloodCls, "startSession", "()V");
	(*env)->CallStaticVoidMethod(env, appfloodCls, mid);
}