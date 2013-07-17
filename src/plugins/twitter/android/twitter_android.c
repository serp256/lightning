#include "plugin_common.h"
#include "twitter_common.h"

static jclass twitterCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(twitterCls,ru/redspell/lightning/plugins/LightTwitter);

value ml_init(value v_consumerKey, value v_consumerSecret) {
	CAMLparam2(v_consumerKey, v_consumerSecret);

	if (!Is_block(v_consumerKey) || !Is_block(v_consumerSecret)) {
		caml_failwith("consumerKey and consumerSecret on Android shouldn't be None values");
	}

	GET_ENV;
	GET_CLS;

	JString_val(j_consumerSecret, Field(v_consumerSecret, 0));
	JString_val(j_consumerKey, Field(v_consumerKey, 0));

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, twitterCls, "init", "(Ljava/lang/String;Ljava/lang/String;)V");

	(*env)->CallStaticVoidMethod(env, twitterCls, mid, j_consumerKey, j_consumerSecret);
	(*env)->DeleteLocalRef(env, j_consumerKey);
	(*env)->DeleteLocalRef(env, j_consumerSecret);

	CAMLreturn(Val_unit);
}

value ml_tweet(value v_success, value v_fail, value v_text) {
	CAMLparam3(v_success, v_fail, v_text);

	GET_ENV;
	GET_CLS;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, twitterCls, "tweet", "(Ljava/lang/String;II)V");

	REG_CALLBACK(success);
	REG_CALLBACK(fail);

	jstring j_text = (*env)->NewStringUTF(env, String_val(v_text));
	(*env)->CallStaticVoidMethod(env, twitterCls, mid, j_text, (jint)success, (jint)fail);
	(*env)->DeleteLocalRef(env, j_text);

	CAMLreturn(Val_unit);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightTwitter_00024Callbacks_nativeSuccess(JNIEnv *env, jobject this, jint cb) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightTwitter_00024Callbacks_nativeSuccess call");
	caml_callback(*(value*)cb, Val_unit);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightTwitter_00024Callbacks_nativeFail(JNIEnv *env, jobject this, jint cb, jstring reason) {
	const char* c_reason = (*env)->GetStringUTFChars(env, reason, JNI_FALSE);
	caml_callback(*(value*)cb, caml_copy_string(c_reason));
	(*env)->ReleaseStringUTFChars(env, reason, c_reason);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightTwitter_00024Callbacks_nativeFree(JNIEnv *env, jobject this, jint success, jint fail) {
	UNREG_CALLBACK((value*)success);
	UNREG_CALLBACK((value*)fail);
}