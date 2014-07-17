#include "lightning_android.h"
#include "engine.h"

void ml_authorization_grant(value url, value closeBt) {
	// jclass oauthCls = (*ML_ENV)->FindClass(ML_ENV,"ru/redspell/lightning/OAuth");
	jclass oauthCls = engine_find_class("ru/redspell/lightning/v2/OAuth");
	jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, oauthCls, "dialog","(Ljava/lang/String;)V");

	char* curl = String_val(url);
	jstring jurl = (*ML_ENV)->NewStringUTF(ML_ENV, curl);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, oauthCls, mid, jurl);

	(*ML_ENV)->DeleteLocalRef(ML_ENV, jurl);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, oauthCls);
}

void oauth_redirect(void *data) {
	CAMLparam0();
	CAMLlocal1(vurl);

	jstring jurl = (jstring)data;
	JSTRING_TO_VAL(jurl, vurl);
	caml_callback(*caml_named_value("oauth_redirected"), vurl);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, jurl);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_OAuthDialog_onRedirect(JNIEnv *env, jobject this, jstring url) {
	RUN_ON_ML_THREAD(&oauth_redirect, (void*)(*env)->NewGlobalRef(env, url));
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_OAuthDialog_onClose(JNIEnv *env, jobject this, jstring url) {
	RUN_ON_ML_THREAD(&oauth_redirect, (void*)(*env)->NewGlobalRef(env, url));
}