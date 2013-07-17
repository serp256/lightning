#include "mlwrapper_android.h"

void ml_authorization_grant(value url, value closeBt) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	jclass oauthCls = (*env)->FindClass(env,"ru/redspell/lightning/OAuth");
	jmethodID mid = (*env)->GetStaticMethodID(env, oauthCls, "dialog","(Ljava/lang/String;)V");

	char* curl = String_val(url);
	jstring jurl = (*env)->NewStringUTF(env, curl);
	(*env)->CallStaticVoidMethod(env, oauthCls, mid, jurl);

	(*env)->DeleteLocalRef(env, jurl);
	(*env)->DeleteLocalRef(env, oauthCls);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_OAuthDialog_00024DefaultRedirectHandler_run(JNIEnv *env, jobject this, jstring url) {
	static value* oauth_redirect = 0;
	if (!oauth_redirect) oauth_redirect = (value*)caml_named_value("oauth_redirected");

	const char *curl = (*env)->GetStringUTFChars(env, url, JNI_FALSE);
	caml_callback(*oauth_redirect, caml_copy_string(curl));
	(*env)->ReleaseStringUTFChars(env, url, curl);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_OAuthDialog_00024DefaultDialogClosedRunnable_run(JNIEnv *env, jobject this, jstring url) {
	Java_ru_redspell_lightning_OAuthDialog_00024DefaultRedirectHandler_run(env, this, url);
}