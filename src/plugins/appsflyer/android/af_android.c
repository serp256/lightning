
#include "lightning_android.h"
#include "engine.h"

#define env ML_ENV

value ml_af_set_key(value appid, value key) {
	PRINT_DEBUG("ml_af_set_key");
	jclass afCls = engine_find_class("com/appsflyer/AppsFlyerLib");
	jmethodID jSetKeyM = (*env)->GetStaticMethodID(env,afCls,"setAppsFlyerKey","(Ljava/lang/String;)V");
	jstring jkey = (*env)->NewStringUTF(env, String_val(key));
	(*env)->CallStaticVoidMethod(env,afCls,jSetKeyM,jkey);
	(*env)->DeleteLocalRef(env,jkey);
	return Val_unit;
}


value ml_af_set_user_id(value uid) {
	return Val_unit;
}


value ml_af_set_currency_code(value code) {
	return Val_unit;
}


value ml_af_get_uid(value p) {
	PRINT_DEBUG("ml_send_tracking");
	jclass afCls = engine_find_class("com/appsflyer/AppsFlyerLib");
	jmethodID jGetAppUserIdM = (*env)->GetStaticMethodID(env,afCls,"getAppsFlyerUID","(Landroid/content/Context;)Ljava/lang/String;");
	jobject jcontext = JAVA_ACTIVITY;
	jstring jUID = (*env)->CallStaticObjectMethod(env,afCls,jGetAppUserIdM,jcontext);
	const char *cuid = (*env)->GetStringUTFChars(env,jUID,JNI_FALSE);
	value res = caml_copy_string(cuid);
	(*env)->ReleaseStringUTFChars(env,jUID,cuid);
	(*env)->DeleteLocalRef(env,jcontext);
	return res;
}


value ml_af_send_tracking(value p) {
	PRINT_DEBUG("ml_send_tracking");
	jclass afCls = engine_find_class("com/appsflyer/AppsFlyerLib");
	static jmethodID jSetTrackingM = NULL;
	if (jSetTrackingM == NULL) jSetTrackingM = (*env)->GetStaticMethodID(env,afCls,"sendTracking","(Landroid/content/Context;)V");
	jobject jcontext = JAVA_ACTIVITY;
	(*env)->CallStaticVoidMethod(env,afCls,jSetTrackingM,jcontext);
	return Val_unit;
}


value ml_af_send_tracking_with_event(value evkey,value evval) {
	jclass afCls = engine_find_class("com/appsflyer/AppsFlyerLib");
	PRINT_DEBUG("ml_send_tracking_with_event");
	static jmethodID jSetTrackingEvM = NULL;
	if (jSetTrackingEvM == NULL) jSetTrackingEvM = (*env)->GetStaticMethodID(env,afCls,"sendTrackingWithEvent","(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V");
	jobject jcontext = JAVA_ACTIVITY;
	jstring jevkey = (*env)->NewStringUTF(env,String_val(evkey));
	jstring jevval = (*env)->NewStringUTF(env,String_val(evval));
	(*env)->CallStaticVoidMethod(env,afCls,jSetTrackingEvM,jcontext,jevkey,jevval);
	(*env)->DeleteLocalRef(env,jevkey);
	(*env)->DeleteLocalRef(env,jevval);
	(*env)->DeleteLocalRef(env,jcontext);
	return Val_unit;
}
