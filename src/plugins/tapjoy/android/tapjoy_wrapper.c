#include "plugin_common.h"

static jclass gTapjoyCls = 0;

#define GET_CLS GET_PLUGIN_CLASS(gTapjoyCls,ru/redspell/lightning/plugins/LightTapjoy);

void ml_tapjoy_init(value ml_appID,value ml_secretKey) {
	GET_ENV;
	GET_CLS;

	JString_val(j_appId, ml_appID);
	JString_val(j_secKey, ml_secretKey);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, gTapjoyCls, "init", "(Ljava/lang/String;Ljava/lang/String;)V");

	(*env)->CallStaticVoidMethod(env, gTapjoyCls, mid, j_appId, j_secKey);
	(*env)->DeleteLocalRef(env, j_appId);
	(*env)->DeleteLocalRef(env, j_secKey);

	/* ENABLE LOGGING
	// TapjoyLog.enableLogging(true);
	jclass jTapjoyLog = (*env)->FindClass(env,"com/tapjoy/TapjoyLog");
	jmethodID jenableLogging = (*env)->GetStaticMethodID(env,jTapjoyLog,"enableLogging","(Z)V");
	(*env)->CallStaticVoidMethod(env,jTapjoyLog,jenableLogging,JNI_TRUE);
	(*env)->DeleteLocalRef(env,jTapjoyLog);
	PRINT_DEBUG("LOGGING ENABLED");
	*/



	//
	//TapjoyConnect.requestTapjoyConnect(getContext().getApplicationContext(),appID,secretKey);
/*	jobject jAppContext = jApplicationContext(env);

	jclass cls = (*env)->FindClass(env, "com/tapjoy/TapjoyConnect");
	gTapjoyCls = (*env)->NewGlobalRef(env, cls);
	jstring appID = (*env)->NewStringUTF(env,String_val(ml_appID));
	jstring secretKey = (*env)->NewStringUTF(env,String_val(ml_secretKey));
	jmethodID requestTapjoyMethod = (*env)->GetStaticMethodID(env,cls,"requestTapjoyConnect","(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env,cls,requestTapjoyMethod,jAppContext,appID,secretKey);
	(*env)->DeleteLocalRef(env,jAppContext);
	(*env)->DeleteLocalRef(env,appID);
	(*env)->DeleteLocalRef(env,secretKey);
	(*env)->DeleteLocalRef(env,cls);*/
}


/*static jobject inline getTapjoyJNI(JNIEnv *env) {
	static jobject gTapjoy = NULL;
	if (!gTapjoy) {

		if (!gTapjoyCls) caml_failwith("Tapjoy not initialized");
		jmethodID mid = (*env)->GetStaticMethodID(env, gTapjoyCls, "getTapjoyConnectInstance", "()Lcom/tapjoy/TapjoyConnect;");
		jobject tapjoy = (*env)->CallStaticObjectMethod(env, gTapjoyCls, mid);

		gTapjoy = (*env)->NewGlobalRef(env, tapjoy);

		(*env)->DeleteLocalRef(env, tapjoy);
	}
	return gTapjoy;
}*/

void ml_tapjoy_show_offers_with_currency(value currency, value show_selector) {
	GET_ENV;
	GET_CLS;

	JString_val(j_currency, currency);
	jboolean jshow_selector = Bool_val(show_selector);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, gTapjoyCls, "showOffersWithCurrencyID", "(Ljava/lang/String;Z)V");

	(*env)->CallStaticVoidMethod(env, gTapjoyCls, mid, j_currency, jshow_selector);
	(*env)->DeleteLocalRef(env, j_currency);
/*	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jobject jTapjoy = getTapjoyJNI(env);

	jstring jcurrency = (*env)->NewStringUTF(env, String_val(currency));
	jboolean jshow_selector = Bool_val(show_selector);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "showOffersWithCurrencyID", "(Ljava/lang/String;Z)V");
	}

	(*env)->CallVoidMethod(env, jTapjoy, mid, jcurrency, jshow_selector);
	(*env)->DeleteLocalRef(env, jcurrency);*/
}

void ml_tapjoy_show_offers() {
	GET_ENV;
	GET_CLS;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, gTapjoyCls, "showOffers", "()V");

	(*env)->CallStaticVoidMethod(env, gTapjoyCls, mid);

/*	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jobject jTapjoy = getTapjoyJNI(env);
	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "showOffers", "()V");
	}

	(*env)->CallVoidMethod(env, jTapjoy, mid);*/
}

void ml_tapjoy_set_user_id(value uid) {
	GET_ENV;
	GET_CLS;

	JString_val(j_uid, uid);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, gTapjoyCls, "setUserID", "(Ljava/lang/String;)V");

	(*env)->CallStaticVoidMethod(env, gTapjoyCls, mid, j_uid);
	(*env)->DeleteLocalRef(env, j_uid);

/*	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jobject jTapjoy = getTapjoyJNI(env);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "setUserID", "(Ljava/lang/String;)V");
	}

	jstring juid = (*env)->NewStringUTF(env, String_val(uid));
	(*env)->CallVoidMethod(env, jTapjoy, mid, juid);
	(*env)->DeleteLocalRef(env, juid);*/
}

void ml_tapjoy_action_complete(value action) {
	GET_ENV;
	GET_CLS;

	JString_val(j_action, action);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, gTapjoyCls, "actionComplete", "(Ljava/lang/String;)V");

	(*env)->CallStaticVoidMethod(env, gTapjoyCls, mid, j_action);
	(*env)->DeleteLocalRef(env, j_action);


/*	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jobject jTapjoy = getTapjoyJNI(env);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "actionComplete", "(Ljava/lang/String;)V");
	};

	jstring jaction = (*env)->NewStringUTF(env,String_val(action)); 

	(*env)->CallVoidMethod(env,jTapjoy,mid,jaction);

	(*env)->DeleteLocalRef(env,jaction);*/

}
