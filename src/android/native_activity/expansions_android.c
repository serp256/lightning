#include "lightning_android.h"
#include "engine.h"

value ml_downloadExpansions(value vpubkey) {
	PRINT_DEBUG("ml_downloadExpansions");

	CAMLparam1(vpubkey);
	jstring jpubkey = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(vpubkey));
	PRINT_DEBUG("2");
	jclass cls = lightning_find_class("ru/redspell/lightning/v2/Expansions");
	jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "download", "(Ljava/lang/String;)V");
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jpubkey);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jpubkey);

	CAMLreturn(Val_unit);
}

void expansions_success(void *data) {
	CAMLparam0();
	caml_callback(*caml_named_value("expansionsComplete"), Val_unit);
	CAMLreturn0;
}

void expansions_fail(void *data) {
	CAMLparam0();
	CAMLlocal1(vreason);

	jstring jreason = (jstring)data;
	JSTRING_TO_VAL(jreason, vreason);
	caml_callback(*caml_named_value("expansionsError"), vreason);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, jreason);

	CAMLreturn0;
}

void expansions_progress(void *data) {
	CAMLparam0();

	jlong *progress = (jlong*)data;
	caml_callback3(*caml_named_value("expansionsProgress"), Val_int(progress[0]), Val_int(progress[1]), Val_int(progress[2]));
	free(progress);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Expansions_00024DownloaderClient_success(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_v2_Expansions_00024DownloaderClient_success");
	RUN_ON_ML_THREAD(&expansions_success, NULL);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Expansions_00024DownloaderClient_fail(JNIEnv *env, jobject this, jstring reason) {
	PRINT_DEBUG("Java_ru_redspell_lightning_v2_Expansions_00024DownloaderClient_fail");
	RUN_ON_ML_THREAD(&expansions_fail, (void*)(*env)->NewGlobalRef(env, reason));
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Expansions_00024DownloaderClient_progress(JNIEnv *env, jobject this, jlong jtotal, jlong jprogress, jlong jtime) {
	PRINT_DEBUG("Java_ru_redspell_lightning_v2_Expansions_00024DownloaderClient_progress");

	jlong *p = (jlong*)malloc(sizeof(jlong) * 3);
	p[0] = jtotal;
	p[1] = jprogress;
	p[2] = jtime;

	RUN_ON_ML_THREAD(&expansions_progress, (void*)p);
}
