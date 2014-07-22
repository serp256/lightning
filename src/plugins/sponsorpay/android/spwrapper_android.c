#include "plugin_common.h"

static jclass sponsorpayCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(sponsorpayCls,ru/redspell/lightning/plugins/LightSponsorpay);

void ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken) {
	GET_ENV;
	GET_CLS;

	PRINT_DEBUG("user id: %s", Is_block(v_userId) ? String_val(Field(v_userId, 0)) : "");

	jstring j_appId = (*env)->NewStringUTF(env, String_val(v_appId));
	jstring j_userId = (*env)->NewStringUTF(env, Is_block(v_userId) ? String_val(Field(v_userId, 0)) : "");
	jstring j_securityToken = (*env)->NewStringUTF(env, Is_block(v_securityToken) ? String_val(Field(v_securityToken, 0)) : "");

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "init", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid, j_appId, j_userId, j_securityToken);

	(*env)->DeleteLocalRef(env, j_appId);
	(*env)->DeleteLocalRef(env, j_userId);
	(*env)->DeleteLocalRef(env, j_securityToken);
}

void ml_sponsorPay_showOffers() {
	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "showOfferts", "()V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid);
}
