#include "lightning_android.h"
#include "engine_android.h"
#include <caml/callback.h>

static jclass servCls = NULL;
#define GET_ENV JNIEnv *env = ML_ENV;
#define STATIC_MID(cls, name, sig) static jmethodID mid = 0; if (!mid) mid = (*env)->GetStaticMethodID(env, cls, #name, sig);
#define GET_CLS if (!servCls) servCls = engine_find_class("ru/redspell/lightning/download_service/LightDownloadService");

value ml_DownloadNative(value vcompress, value vmd5, value vurl, value vpath, value verrCb, value vprgrssCb, value vcb) {
	CAMLparam5(vurl, vpath, verrCb, vprgrssCb, vcb);
	CAMLxparam2(vcompress,vmd5);

	PRINT_DEBUG("ml_DownloadNative");

	value* success;
	value* fail;
	value* progress;

	REG_CALLBACK(vcb, success);
	REG_OPT_CALLBACK(verrCb, fail);
	REG_OPT_CALLBACK(vprgrssCb, progress);

	GET_ENV;
	GET_CLS;


	STATIC_MID(servCls, download, "(ZLjava/lang/String;Ljava/lang/String;Ljava/lang/String;III)V");
	jstring jurl = (*env)->NewStringUTF(env, String_val(vurl));
	jstring jpath= (*env)->NewStringUTF(env, String_val(vpath));
	jstring jmd5= (*env)->NewStringUTF(env, String_val(vmd5));
	jboolean compress = Bool_val(vcompress) == 0 ? JNI_FALSE: JNI_TRUE;
	(*env)->CallStaticVoidMethod(env, servCls, mid, compress, jmd5, jurl, jpath, (jint)success, (jint)fail, (jint)progress);

	CAMLreturn(Val_unit);
}

value ml_DownloadNative_byte(value *argv, int n) {
	return ml_DownloadNative(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}

typedef struct {
	value *success;
	value *fail;
	value *progress;
	jobjectArray files;
} download_success_t;

void download_success (void *d) {
	CAMLparam0();
	CAMLlocal2(retval, head);

	GET_ENV;
	retval = Val_int(0);

	download_success_t *data = (download_success_t*)d;

	int cnt = (*env)->GetArrayLength(env, data->files);
	int i;
	for (i = 0; i < cnt; i++) {
		jstring jfile = (*env)->GetObjectArrayElement(env, data->files, i);
		const char* cfile = (*env)->GetStringUTFChars(env, jfile, JNI_FALSE);

		head = caml_alloc_tuple(2);
		Store_field(head, 0, caml_copy_string(cfile));
		Store_field(head, 1, retval);

		retval = head;

		(*env)->ReleaseStringUTFChars(env, jfile, cfile);
		(*env)->DeleteLocalRef(env, jfile);
	}

	RUN_CALLBACK(data->success, retval);
	FREE_CALLBACK(data->fail);
	FREE_CALLBACK(data->success);
	FREE_CALLBACK(data->progress);
	(*env)->DeleteGlobalRef(env,data->files); 
	free(data);
	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jint jprogress, jobjectArray jfiles) {
	PRINT_DEBUG("Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadSuccess_nativeRun");
	download_success_t *data = (download_success_t*)malloc(sizeof(download_success_t));
	data->success  = (value*)jsuccess;
	data->fail     = (value*)jfail;
	data->progress = (value*)jprogress;
	data->files    = (*env)->NewGlobalRef(env, jfiles);
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
	RUN_CALLBACK2(fail->fail, Val_int(0), caml_copy_string(fail->reason));
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
	download_progress_t *progress_data= (download_progress_t*)data;
	RUN_CALLBACK3(progress_data->callback, caml_copy_double(progress_data->progress), caml_copy_double(progress_data->total), Val_unit);
	free(progress_data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_download_1service_LightDownloadService_00024DownloadProgress_nativeRun(JNIEnv *env, jobject this, jint jcallback, jdouble jprogress, jdouble jtotal) {
	download_progress_t *data= (download_progress_t*)malloc(sizeof(download_progress_t));

	data->callback= (value*)jcallback;
	data->progress= jprogress;
	data->total= jtotal;

	RUN_ON_ML_THREAD(&download_progress, data);
}
