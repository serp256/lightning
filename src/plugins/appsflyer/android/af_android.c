
#include "mlwrapper_android.h"


static jclass afCls = NULL;

jclass getAFCls(JNIEnv *env) {
	if (afCls == NULL) {
		jclass cls = (*env)->FindClass(env, "com/appsflyer/AppsFlyerLib");
		if (cls == NULL) caml_failwith("AppsFlyer not found");
		afCls = (*env)->NewGlobalRef(env,cls);
		(*env)->DeleteLocalRef(env,cls);
	}
	return afCls;
}

value ml_af_set_key(value key) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("ml_af_set_key");
	jclass afCls = getAFCls(env);
	jmethodID jSetKeyM = (*env)->GetStaticMethodID(env,afCls,"setAppsFlyerKey","(Ljava/lang/String;)V");
	jstring jkey = (*env)->NewStringUTF(env, String_val(key));
	(*env)->CallStaticVoidMethod(env,afCls,jSetKeyM,jkey);
	(*env)->DeleteLocalRef(env,jkey);
	return Val_unit;
}


value ml_af_set_user_id(value uid) {
	return Val_unit;
}


value ml_set_currency_code(value code) {
	return Val_unit;
}


value ml_send_tracking(value p) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("ml_send_tracking");
	jclass afCls = getAFCls(env);
	static jmethodID jSetTrackingM = NULL;
	if (jSetTrackingM == NULL) jSetTrackingM = (*env)->GetStaticMethodID(env,afCls,"sendTracking","(Landroid/content/Context;)V");
	jobject jcontext = jApplicationContext(env);
	(*env)->CallStaticVoidMethod(env,afCls,jSetTrackingM,jcontext);
	return Val_unit;
}


value ml_send_tracking_with_event(value evkey,value evval) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass afCls = getAFCls(env);
	PRINT_DEBUG("ml_send_tracking_with_event");
	static jmethodID jSetTrackingEvM = NULL;
	if (jSetTrackingEvM == NULL) jSetTrackingEvM = (*env)->GetStaticMethodID(env,afCls,"sendTrackingWithEvent","(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V");
	jobject jcontext = jApplicationContext(env);
	jstring jevkey = (*env)->NewStringUTF(env,String_val(evkey));
	jstring jevval = (*env)->NewStringUTF(env,String_val(evval));
	(*env)->CallStaticVoidMethod(env,afCls,jSetTrackingEvM,jcontext,jevkey,jevval);
	(*env)->DeleteLocalRef(env,jevkey);
	(*env)->DeleteLocalRef(env,jevval);
	(*env)->DeleteLocalRef(env,jcontext);
	return Val_unit;
}
