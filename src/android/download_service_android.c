#include "lightning_android.h"
#include "engine_android.h"
#include <caml/callback.h>

static jclass servCls = NULL;
#define GET_ENV JNIEnv *env = ML_ENV;
#define STATIC_MID(cls, name, sig) static jmethodID mid = 0; if (!mid) mid = (*env)->GetStaticMethodID(env, cls, #name, sig);
#define GET_CLS if (!servCls) servCls = engine_find_class("ru/redspell/lightning/download_service/LightDownloadService");

value ml_DownloadServiceInit(value vsuccess, value vprogress, value vfail) {
	CAMLparam3(vsuccess, vprogress, vfail);

	PRINT_DEBUG("ml_DownloadServiceInit");

	value* success;
	value* fail;
	value* progress;

	REG_CALLBACK(vsuccess, success);
	REG_CALLBACK(vfail, fail);
	REG_OPT_CALLBACK(vprogress, progress);

	GET_ENV;
	GET_CLS;


	STATIC_MID(servCls, init, "(III)V");
	(*env)->CallStaticVoidMethod(env, servCls, mid, (jint)success, (jint)fail, (jint) progress);

	CAMLreturn(Val_unit);
}

value ml_DownloadNative(value vcompress, value vurl, value vpath, value verrCb, value vprgrssCb, value vcb) {
	CAMLparam5(vurl, vpath, verrCb, vprgrssCb, vcb);
	CAMLxparam1(vcompress);

	PRINT_DEBUG("----START DOWNLOAD FILE WITH SERVICE %d", Bool_val(vcompress) );

	value* success;
	value* fail;
	value* progress;

	REG_CALLBACK(vcb, success);
	REG_OPT_CALLBACK(verrCb, fail);
	REG_OPT_CALLBACK(vprgrssCb, progress);

	GET_ENV;
	GET_CLS;


	STATIC_MID(servCls, download, "(ZLjava/lang/String;Ljava/lang/String;III)V");
	jstring jurl = (*env)->NewStringUTF(env, String_val(vurl));
	jstring jpath= (*env)->NewStringUTF(env, String_val(vpath));
	jboolean compress = Bool_val(vcompress) == 0 ? JNI_FALSE: JNI_TRUE;
	(*env)->CallStaticVoidMethod(env, servCls, mid, compress, jurl, jpath, (jint)success, (jint)fail, (jint)progress);

	CAMLreturn(Val_unit);
}

value ml_DownloadNative_byte(value *argv, int n) {
	return ml_DownloadNative(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

void download_success (void *d) {
	value **data = (value**)d;
	PRINT_DEBUG("download_success");
	RUN_CALLBACK(data[0], Val_unit);
	PRINT_DEBUG("1");
	FREE_CALLBACK(data[0]);
	PRINT_DEBUG("2");
	FREE_CALLBACK(data[1]);
	FREE_CALLBACK(data[2]);
	PRINT_DEBUG("3");
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jint jprogress) {
	PRINT_DEBUG("Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadSuccess_nativeRun");
	value **data = (value**)malloc(sizeof(value*)*3);
	data[0] = (value*)jsuccess;
	data[1] = (value*)jfail;
	data[2] = (value*)jprogress;
	RUN_ON_ML_THREAD(&download_success, (void*)data);
}



typedef struct {
	value *success;
	value *fail;
	value *progress;
	char *reason;
} download_fail_t;

void download_fail(void *data) {
	download_fail_t *fail = (download_fail_t*)data;
	RUN_CALLBACK(fail->fail, caml_copy_string(fail->reason));
	FREE_CALLBACK(fail->fail);
	FREE_CALLBACK(fail->success);
	FREE_CALLBACK(fail->progress);
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadFail_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jint jprogress, jstring jreason) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	PRINT_DEBUG("creason '%s'", creason);
	download_fail_t *fail = (download_fail_t*)malloc(sizeof(download_fail_t));

	fail->fail = (value*)jfail;
	fail->success = (value*)jsuccess;
	fail->progress= (value*)jprogress;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&download_fail, fail);
}


typedef struct {
	value *callback;
	double progress;
	double total;
} download_progress_t;

void download_progress (void *data) {
//	PRINT_DEBUG("download_progrss");
	download_progress_t *progress_data= (download_progress_t*)data;
	RUN_CALLBACK3(progress_data->callback, caml_copy_double(progress_data->progress), caml_copy_double(progress_data->total), Val_unit);
	free(progress_data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadProgress_nativeRun(JNIEnv *env, jobject this, jint jcallback, jdouble jprogress, jdouble jtotal) {
//	PRINT_DEBUG("Java_ru_redspell_lightning_download_service_LightDownloadService_00024DownloadProgress_nativeRun");
	download_progress_t *data= (download_progress_t*)malloc(sizeof(download_progress_t));

	data->callback= (value*)jcallback;
	data->progress= jprogress;
	data->total= jtotal;

	RUN_ON_ML_THREAD(&download_progress, data);
}


/*
void download_finish_success (void *d) {
	value **data = (value**)d;
	PRINT_DEBUG("download_finish_success");
	RUN_CALLBACK(data[0], Val_unit);
	FREE_CALLBACK(data[0]);
	FREE_CALLBACK(data[1]);
	FREE_CALLBACK(data[2]);
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadFinishSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jint jprogress) {
	PRINT_DEBUG("Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadFinishSuccess_nativeRun");
	value **data = (value**)malloc(sizeof(value*)*3);
	data[0] = (value*)jsuccess;
	data[1] = (value*)jfail;
	data[2] = (value*)jprogress;
	RUN_ON_ML_THREAD(&download_finish_success, (void*)data);
}

typedef struct {
	value *success;
	value *fail;
	value *progress;
	char *reason;
} download_finish_fail_t;

void download_finish_fail(void *data) {
	download_finish_fail_t *fail = (download_finish_fail_t*)data;
	RUN_CALLBACK(fail->fail, caml_copy_string(fail->reason));
	FREE_CALLBACK(fail->fail);
	FREE_CALLBACK(fail->success);
	FREE_CALLBACK(fail->progress);
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadFinishFail_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jint jprogress, jstring jreason) {
	PRINT_DEBUG("Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadFinishFail_nativeRun");
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	PRINT_DEBUG("creason '%s'", creason);
	download_finish_fail_t *fail = (download_finish_fail_t*)malloc(sizeof(download_finish_fail_t));

	fail->fail = (value*)jfail;
	fail->success = (value*)jsuccess;
	fail->progress= (value*)jprogress;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&download_finish_fail, fail);
}

*/
