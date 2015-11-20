#include "lightning_android.h"
#include "engine_android.h"
#include "plugin_common.h"

static jclass cls = NULL;
static jclass light_cls = NULL;

#define GET_CLS cls = engine_find_class("com/appsflyer/AppsFlyerLib");
#define GET_LIGHT_CLS light_cls = engine_find_class("ru/redspell/lightning/plugins/LightAppsflyer");

value ml_af_set_key(value vappid, value vkey) {
	CAMLparam2(vappid,vkey);
	PRINT_DEBUG("ml_af_set_key");

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, setAppsFlyerKey,"(Ljava/lang/String;)V");
	jstring jkey = (*env)->NewStringUTF(env, String_val(vkey));
	(*env)->CallStaticVoidMethod(env,cls,mid,jkey);
	PRINT_DEBUG("1");
	(*env)->DeleteLocalRef(env,jkey);
	CAMLreturn(Val_unit);
}


value ml_af_set_user_id(value vuid) {
	CAMLparam1(vuid);
	PRINT_DEBUG("ml_af_set_user_id");

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, setCustomerUserId,"(Ljava/lang/String;)V");

	jstring juid  = (*env)->NewStringUTF(env, String_val(vuid));
	(*env)->CallStaticVoidMethod(env, cls, mid, juid);
	PRINT_DEBUG("2");
	(*env)->DeleteLocalRef(env,juid);

	CAMLreturn(Val_unit);
}


value ml_af_set_currency_code(value vcode) {
	CAMLparam1(vcode);
	PRINT_DEBUG("ml_af_set_currency_code");

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, setCurrencyCode,"(Ljava/lang/String;)V");

	jstring jcode  = (*env)->NewStringUTF(env, String_val(vcode));
	(*env)->CallStaticVoidMethod(env, cls, mid, jcode);
	(*env)->DeleteLocalRef(env,jcode);

	CAMLreturn(Val_unit);
}


value ml_af_get_uid(value unit) {
	CAMLparam0();
	PRINT_DEBUG("ml_af_get_uid");
	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, getAppsFlyerUID,"(Landroid/content/Context;)Ljava/lang/String;");


	jobject jcontext = JAVA_ACTIVITY;
	jstring jUID = (*env)->CallStaticObjectMethod(env,cls,mid,jcontext);

	const char *cuid = (*env)->GetStringUTFChars(env,jUID,JNI_FALSE);
	value res = caml_copy_string(cuid);
	(*env)->ReleaseStringUTFChars(env,jUID,cuid);

	CAMLreturn(res);
}


value ml_af_send_tracking(value unit) {
	CAMLparam0();
	PRINT_DEBUG("ml_af_send_tracking");

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, sendTracking,"(Landroid/content/Context;)V");
	jobject jcontext = JAVA_ACTIVITY;
	(*env)->CallStaticVoidMethod(env,cls,mid,jcontext);

	CAMLreturn(Val_unit);
}


value ml_af_track_purchase(value vid, value vcurrency, value vrevenue) {
	PRINT_DEBUG("ml_track_purchase");
	CAMLparam3(vid,vcurrency,vrevenue);

	GET_ENV;
	GET_LIGHT_CLS;


    PRINT_DEBUG("checkpoint1");

	static jmethodID trackPurchaseMid = NULL;
	if (trackPurchaseMid == NULL) trackPurchaseMid = (*env)->GetStaticMethodID(env,light_cls,"trackPurchase","(Ljava/lang/String;Ljava/lang/String;D)V");

    PRINT_DEBUG("checkpoint2");
	jstring jid = (*env)->NewStringUTF(env,String_val(vid));
	jstring jcurrency = (*env)->NewStringUTF(env,String_val(vcurrency));
	(*env)->CallStaticVoidMethod(env,light_cls,trackPurchaseMid,jid,jcurrency,Double_val(vrevenue));

    PRINT_DEBUG("checkpoint6");
	(*env)->DeleteLocalRef(env,jid);
	(*env)->DeleteLocalRef(env,jcurrency);


	CAMLreturn(Val_unit);
}

value ml_af_track_level(value vlevel) {
	PRINT_DEBUG("ml_track_level");
	CAMLparam1(vlevel);

	GET_ENV;
	GET_LIGHT_CLS;


    PRINT_DEBUG("checkpoint1");

	static jmethodID trackLevelMid = NULL;
	if (trackLevelMid == NULL) trackLevelMid = (*env)->GetStaticMethodID(env,light_cls,"trackLevelComplete","(I)V");

    PRINT_DEBUG("checkpoint2");
	(*env)->CallStaticVoidMethod(env,light_cls,trackLevelMid,Int_val(vlevel));


	CAMLreturn(Val_unit);
}

value ml_af_track_tapjoy_event (value unit) {
	PRINT_DEBUG("ml_track_tapjoy_event");
	CAMLparam0();

	GET_ENV;
	GET_LIGHT_CLS;


	static jmethodID trackTapjoyEventMid = NULL;
	if (trackTapjoyEventMid == NULL) trackTapjoyEventMid = (*env)->GetStaticMethodID(env,light_cls,"trackTapjoyEvent","()V");

	(*env)->CallStaticVoidMethod(env,light_cls,trackTapjoyEventMid);

	CAMLreturn(Val_unit);
}
