#include <errno.h>
#include <unistd.h>

#include "mlwrapper_android.h"


#include "light_common.h"
#include "thqueue.h"

#include "caml/mlvalues.h"
#include "caml/memory.h"

#define CURL_DISABLE_TYPECHECK
#include "android/libcurl/curl.h"

#define MIN_ALLOC_SIZE 4096

typedef struct {
	char* url;
	char* path;
	value* cb;
	value* errCb;
} download_request_t;

THQUEUE_INIT(download_reqs,download_request_t*);

static pthread_mutex_t mutex;
static pthread_cond_t cond;
static pthread_t tid;
static thqueue_download_reqs_t* reqs;

static void caml_error(download_request_t* req, int errCode, char* errMes) {
	PRINT_DEBUG("caml_error %d %s", errCode, errMes);

	if (req->errCb) {
		PRINT_DEBUG("call error callback");

		JNIEnv *env; 
		(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);

		static jmethodID curlExtLdrErrorMid;
		if (!curlExtLdrErrorMid) curlExtLdrErrorMid = (*env)->GetMethodID(env, jViewCls, "curlDownloaderError", "(III)V");

		char* _errMes = malloc(strlen(errMes) + 1);
		strcpy(_errMes, errMes);
		(*env)->CallVoidMethod(env, jView, curlExtLdrErrorMid, (int)req, errCode, (int)_errMes);		
		//(*gJavaVM)->DetachCurrentThread(gJavaVM);
	}
}

static void* downloader_thread(void* params) {
	pthread_mutex_lock(&mutex);

	CURL* curl_hndlr = curl_easy_init();
	char* curl_err = (char*)malloc(CURL_ERROR_SIZE);
	curl_easy_setopt(curl_hndlr, CURLOPT_ERRORBUFFER, curl_err);
	curl_easy_setopt(curl_hndlr, CURLOPT_WRITEFUNCTION, NULL);
	curl_easy_setopt(curl_hndlr, CURLOPT_FOLLOWLOCATION, 1);

	JNIEnv *env;
	(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);
	jmethodID curlDownloadSuccessMid = (*env)->GetMethodID(env, jViewCls, "curlDownloaderSuccess", "(I)V");
	//(*gJavaVM)->DetachCurrentThread(gJavaVM);

	while (1) {
		download_request_t* req = thqueue_download_reqs_pop(reqs);

		if (!req) {
			PRINT_DEBUG("waiting...");
			pthread_cond_wait(&cond, &mutex);
		} else {
			PRINT_DEBUG("try loading %s to %s", req->url, req->path);

			size_t pathlen = strlen(req->path);
			char *tmpfname = malloc(pathlen + 13);
			strcpy(tmpfname,req->path);
			strcpy(tmpfname + pathlen,".downloading");
			FILE *fd = fopen(tmpfname,"w");
			if (fd == NULL) {
				strerror_r(errno, curl_err,CURL_ERROR_SIZE);
				caml_error(req, errno, curl_err);
				continue;
			}
			
			curl_easy_setopt(curl_hndlr, CURLOPT_URL, req->url);
			curl_easy_setopt(curl_hndlr,CURLOPT_WRITEDATA,fd);
			int curl_perform_retval = curl_easy_perform(curl_hndlr);

			fclose(fd);
			if (curl_perform_retval) {
				unlink(tmpfname);
				caml_error(req, curl_perform_retval, curl_err);
			} else {
				long respCode;
				curl_easy_getinfo(curl_hndlr, CURLINFO_RESPONSE_CODE, &respCode);

				// if (respCode != 200) {
				// 	caml_error(req, (int)respCode, "http code is not 200");
				// } else {
					PRINT_DEBUG("complete loading %s %ld",req->path, respCode);
					rename(tmpfname,req->path);
					//(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);
					(*env)->CallVoidMethod(env, jView, curlDownloadSuccessMid, (int)req);
					//(*gJavaVM)->DetachCurrentThread(gJavaVM);
					*curl_err = '\0';
				// }
			};
			free(tmpfname);
		}
	};
	return NULL;
}

extern void initCurl();

value ml_DownloadFile(value url, value path, value errCb, value cb) {
	initCurl();

	PRINT_DEBUG("START DOWNLOAD FILE");

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	download_request_t* req = (download_request_t*)malloc(sizeof(download_request_t));

	req->url = (char*)malloc(caml_string_length(url) + 1);
	strcpy(req->url, String_val(url));

	req->path = (char*)malloc(caml_string_length(path) + 1);
	strcpy(req->path, String_val(path));

	req->cb = (value*)malloc(sizeof(value));
	*(req->cb) = cb;
	caml_register_generational_global_root(req->cb);

	if (errCb != Val_int(0)) {
		req->errCb = (value*)malloc(sizeof(value));
		*(req->errCb) = Field(errCb, 0);
		caml_register_generational_global_root(req->errCb);
	} else {
		req->errCb = NULL;
	}

	if (!reqs && !(reqs = thqueue_download_reqs_create())) {
		caml_failwith("cannot create requests queue");
	}

	if (!tid && pthread_create(&tid, NULL, &downloader_thread, NULL)) {
		caml_failwith("cannot create loader thread");
	}

	thqueue_download_reqs_push(reqs, req);
	pthread_cond_signal(&cond);


	return Val_unit;
}

static void freeRequest(download_request_t* req) {
	caml_remove_generational_global_root(req->cb);

	if (req->errCb) {
		caml_remove_generational_global_root(req->errCb);
		free(req->errCb);
	}

	free(req->url);
	free(req->path);
	free(req->cb);	
	free(req);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024CurlDownloaderCallbackRunnable_run(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightView_00024CurlDownloaderCallbackRunnable_run");
	static jfieldID reqFid;

	if (!reqFid) {
		jclass runnableCls = (*env)->GetObjectClass(env, this);
		reqFid = (*env)->GetFieldID(env, runnableCls, "req", "I");
	}

	download_request_t* req = (download_request_t*)(*env)->GetIntField(env, this, reqFid);

	caml_callback(*(req->cb), Val_unit);

	freeRequest(req);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024CurlDownloaderErrorCallbackRunnable_run(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightView_00024CurlDownloaderErrorCallbackRunnable_run");

	static jfieldID reqFid;
	static jfieldID errCodeMid;
	static jfieldID errMesMid;

	if (!reqFid) {
		jclass runnableCls = (*env)->GetObjectClass(env, this);
		reqFid = (*env)->GetFieldID(env, runnableCls, "req", "I");
		errCodeMid = (*env)->GetFieldID(env, runnableCls, "errCode", "I");
		errMesMid = (*env)->GetFieldID(env, runnableCls, "errMes", "I");
	}

	download_request_t* req = (download_request_t*)(*env)->GetIntField(env, this, reqFid);
	int errCode = (*env)->GetIntField(env, this, errCodeMid);
	char* errMes = (char*)(*env)->GetIntField(env, this, errMesMid);

	caml_callback2(*(req->errCb), Val_int(errCode), caml_copy_string(errMes));

	free(errMes);
	freeRequest(req);
}
