#include "plugin_common.h"

static jclass sponsorpayCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(sponsorpayCls,ru/redspell/lightning/plugins/LightSponsorpay);

void ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken, value v_test) {
	CAMLparam4(v_appId, v_userId, v_securityToken, v_test);
	GET_ENV;
	GET_CLS;

	PRINT_DEBUG("user id: %s", Is_block(v_userId) ? String_val(Field(v_userId, 0)) : "");

	jstring j_appId = (*env)->NewStringUTF(env, String_val(v_appId));
	jstring j_userId = (*env)->NewStringUTF(env, Is_block(v_userId) ? String_val(Field(v_userId, 0)) : "");
	jstring j_securityToken = (*env)->NewStringUTF(env, Is_block(v_securityToken) ? String_val(Field(v_securityToken, 0)) : "");

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "init", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid, j_appId, j_userId, j_securityToken, v_test == Val_true? JNI_TRUE: JNI_FALSE);

	(*env)->DeleteLocalRef(env, j_appId);
	(*env)->DeleteLocalRef(env, j_userId);
	(*env)->DeleteLocalRef(env, j_securityToken);
	CAMLreturn0;
}

void ml_sponsorPay_showOffers() {
	PRINT_DEBUG ("sp_ml_showOffers");
	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "showOffers", "()V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid);
}

void ml_request_video(value vcallback) {
	CAMLparam1(vcallback);
	PRINT_DEBUG ("sp_ml_request_video");

	value *req_callback;
	REG_CALLBACK(vcallback,req_callback);

	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "requestVideos", "(I)V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid,(jint)req_callback);
	CAMLreturn0;
}

void ml_show_video(value vcallback) {
	CAMLparam1(vcallback);
	PRINT_DEBUG ("sp_ml_show_video");

	value *callback;
	REG_CALLBACK(vcallback,callback);

	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "showVideos", "(I)V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid,(jint)callback);
	CAMLreturn0;
}

typedef struct {
    value *callbck;
    jboolean flag;
} spandroid_callback_with_bool_t;

void spandroid_callback_with_bool(void *d) {
    PRINT_DEBUG("spandroid_callback_with_bool");

    spandroid_callback_with_bool_t *data = (spandroid_callback_with_bool_t*)d;
    RUN_CALLBACK(data->callbck, (data->flag == JNI_TRUE ? Val_true: Val_false));
		FREE_CALLBACK(data->callbck);

    free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightSponsorpay_00024CamlParamCallbackInt_run(JNIEnv *env, jobject this) {
    PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightSponsorpay_00024CamlParamCallbackInt_run");

    static jfieldID callbackFid;
    static jfieldID paramFid;

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        paramFid = (*env)->GetFieldID(env, selfCls, "flag", "Z");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    spandroid_callback_with_bool_t *data = (spandroid_callback_with_bool_t*)malloc(sizeof(spandroid_callback_with_bool_t));
    data->callbck = (value*)(*env)->GetIntField(env, this, callbackFid);
    data->flag = (*env)->GetBooleanField(env, this, paramFid);

    RUN_ON_ML_THREAD(&spandroid_callback_with_bool, (void*)data);
}
