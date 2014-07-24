#include "lightning_android.h"
#include "engine_android.h"

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

void rnandroid_success(void *data) {
	PRINT_DEBUG("rnandroid_success");

	jstring jregid = (jstring)data;
	value vregid;
	JSTRING_TO_VAL(jregid, vregid)
	caml_callback(*caml_named_value("remote_notifications_success"), vregid);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, jregid);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightRemoteNotifications_successCallback(JNIEnv *env, jobject this, jstring jregid) {
	RUN_ON_ML_THREAD(&rnandroid_success, (void*)(*env)->NewGlobalRef(env, jregid));
}

void rnandroid_err(void *data) {
	PRINT_DEBUG("rnandroid_err");

	jstring jerr = (jstring)data;
	value verr;
	JSTRING_TO_VAL(jerr, verr)
	caml_callback(*caml_named_value("remote_notifications_error"), verr);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, jerr);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightRemoteNotifications_errorCallback(JNIEnv *env, jobject this, jstring jerr) {
	RUN_ON_ML_THREAD(&rnandroid_err, (void*)(*env)->NewGlobalRef(env, jerr));
}
