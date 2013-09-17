
#include "mlwrapper_android.h"


static jclass rnCls = NULL;

static jobject getRnCls(JNIEnv *env) {
	if (rnCls == NULL) {
		jclass cls = (*env)->FindClass(env, "ru/redspell/lightning/plugins/LightRemoteNotifications");
		if (cls == NULL) caml_failwith("RemoteNotifications not found");
		rnCls = (*env)->NewGlobalRef(env,cls);
		(*env)->DeleteLocalRef(env,cls);
	}
	return rnCls;
}

static jobject jRemoteNotifications = NULL;


value ml_rnInit(value rntype_unused, value sender_id) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("ml_remote_notifications_init");
	jclass rnCls = getRnCls(env);
	jmethodID jInitM = (*env)->GetStaticMethodID(env,rnCls,"init","(Ljava/lang/String;)Lru/redspell/lightning/plugins/LightRemoteNotifications;");
	jstring jsender_id = (*env)->NewStringUTF(env,String_val(sender_id));
	jobject jobj = (*env)->CallStaticObjectMethod(env,rnCls,jInitM,jsender_id);
	if (jobj == NULL) return Val_false;
	jRemoteNotifications = (*env)->NewGlobalRef(env,jobj);
	(*env)->DeleteLocalRef(env,jsender_id);
	(*env)->DeleteLocalRef(env,jobj);
	return Val_true;
}



JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightRemoteNotifications_successCallback(JNIEnv *env, jobject this, jstring jregid) {
	PRINT_DEBUG("ml_rn_success");
	value *ml_success = caml_named_value("remote_notifications_success");
	const char *cregid = (*env)->GetStringUTFChars(env,jregid,JNI_FALSE);
	value regid = caml_copy_string(cregid);
	caml_callback(*ml_success,regid);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightRemoteNotifications_errorCallback(JNIEnv *env, jobject this, jstring jerr) {
	PRINT_DEBUG("ml_rn_fail");
	value *ml_fail = caml_named_value("remote_notifications_error");
	const char *cerr = (*env)->GetStringUTFChars(env,jerr,JNI_FALSE);
	value err = caml_copy_string(cerr);
	caml_callback(*ml_fail,err);
}
