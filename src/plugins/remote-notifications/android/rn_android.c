#include "lightning_android.h"
#include "engine.h"

static jobject jRemoteNotifications = NULL;


value ml_rnInit(value rntype_unused, value sender_id) {
	PRINT_DEBUG("ml_remote_notifications_init");
	jclass rnCls = engine_find_class("ru/redspell/lightning/plugins/LightRemoteNotifications");
	jmethodID jInitM = (*ML_ENV)->GetStaticMethodID(ML_ENV,rnCls,"init","(Ljava/lang/String;)Lru/redspell/lightning/plugins/LightRemoteNotifications;");
	jstring jsender_id = (*ML_ENV)->NewStringUTF(ML_ENV,String_val(sender_id));
	jobject jobj = (*ML_ENV)->CallStaticObjectMethod(ML_ENV,rnCls,jInitM,jsender_id);
	if (jobj == NULL) return Val_false;
	jRemoteNotifications = (*ML_ENV)->NewGlobalRef(ML_ENV,jobj);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jsender_id);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jobj);
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
