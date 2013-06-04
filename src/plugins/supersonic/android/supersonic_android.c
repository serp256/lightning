#include "plugin_common.h"

static jclass supersonicCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(supersonicCls,ru/redspell/lightning/plugins/LightSupersonic);

void ml_supersonicInit(value v_appKey, value v_appUid) {
	GET_ENV;
	GET_CLS;

	jstring j_appKey = (*env)->NewStringUTF(env, String_val(v_appKey));
	jstring j_appUid = (*env)->NewStringUTF(env, String_val(v_appUid));

	jmethodID mid = (*env)->GetStaticMethodID(env, supersonicCls, "init", "(Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, supersonicCls, mid, j_appKey, j_appUid);

	(*env)->DeleteLocalRef(env, j_appKey);
	(*env)->DeleteLocalRef(env, j_appUid);
}

void ml_supersonicShowOffers() {
	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, supersonicCls, "showOfferts", "()V");
	(*env)->CallStaticVoidMethod(env, supersonicCls, mid);
}
