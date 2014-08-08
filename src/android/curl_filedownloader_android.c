#include <errno.h>
#include <unistd.h>

#include "lightning_android.h"
#include "engine_android.h"

#include "thqueue.h"


#define CURL_DISABLE_TYPECHECK
#include "android/libcurl/curl.h"

#define MIN_ALLOC_SIZE 4096

typedef struct {
	char *url;
	char *path;
	value *cb;
	value *errCb;
	value *prgrssCb;
} download_request_t;

THQUEUE_INIT(download_reqs,download_request_t*);

static pthread_mutex_t mutex;
static pthread_cond_t cond;
static pthread_t tid;
static thqueue_download_reqs_t* reqs;

static void freeRequest(download_request_t* req) {
	caml_remove_generational_global_root(req->cb);

	if (req->errCb) {
		caml_remove_generational_global_root(req->errCb);
		free(req->errCb);
	}

	if (req->prgrssCb) {
		caml_remove_generational_global_root(req->prgrssCb);
		free(req->prgrssCb);
	}

	free(req->url);
	free(req->path);
	free(req->cb);
	free(req);
}

typedef struct {
	download_request_t *req;
	int err_code;
	char *err_mes;
} curl_filedownloader_error_t;

typedef struct {
	value *callback;
	double total;
	double now;
} curl_filedownloader_progress_t;

void curl_filedownloader_success(void *data) {
	download_request_t *req = (download_request_t*)data;
	caml_callback(*(req->cb), Val_unit);
	freeRequest(req);
}

void curl_filedownloader_error(void *data) {
	curl_filedownloader_error_t *error = (curl_filedownloader_error_t*)data;
	caml_callback2(*(error->req->errCb), Val_int(error->err_code), caml_copy_string(error->err_mes));
	free(error->err_mes);
	freeRequest(error->req);
	free(error);
}

void curl_filedownloader_progress(void *data) {
	curl_filedownloader_progress_t *progress = (curl_filedownloader_progress_t*)data;
	caml_callback3(*progress->callback, caml_copy_double(progress->now), caml_copy_double(progress->total), Val_unit);
	free(progress);
}

static void caml_error(download_request_t* req, int errCode, char* errMes) {
	if (req->errCb) {
		char* err_mes = malloc(strlen(errMes) + 1);
		strcpy(err_mes, errMes);
		
		curl_filedownloader_error_t *error = (curl_filedownloader_error_t*)malloc(sizeof(curl_filedownloader_error_t));
		error->req = req;
		error->err_code = errCode;
		error->err_mes = err_mes;

		RUN_ON_ML_THREAD(&curl_filedownloader_error, (void*)error);
	}
}

static int progress(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
	value* cb = (value*)clientp;

	if (cb) {
		curl_filedownloader_progress_t *progress = (curl_filedownloader_progress_t*)malloc(sizeof(curl_filedownloader_progress_t));

		progress->callback = cb;
		progress->total = dltotal;
		progress->now = dlnow;

		RUN_ON_ML_THREAD(&curl_filedownloader_progress, (void*)progress);
	}

	return 0;
}

static void* downloader_thread(void* params) {
	pthread_mutex_lock(&mutex);

	CURL* curl_hndlr = curl_easy_init();
	char* curl_err = (char*)malloc(CURL_ERROR_SIZE);
	curl_easy_setopt(curl_hndlr, CURLOPT_ERRORBUFFER, curl_err);
	curl_easy_setopt(curl_hndlr, CURLOPT_WRITEFUNCTION, NULL);
	curl_easy_setopt(curl_hndlr, CURLOPT_FOLLOWLOCATION, 1);

	while (1) {
		download_request_t* req = thqueue_download_reqs_pop(reqs);

		if (!req) {
			PRINT_DEBUG("waiting...");
			pthread_cond_wait(&cond, &mutex);
		} else {
			PRINT_DEBUG("try loading %s to %s", req->url, req->path);

			size_t pathlen = strlen(req->path);
			char *tmpfname = malloc(pathlen + 13);
			strcpy(tmpfname, req->path);
			strcpy(tmpfname + pathlen,".downloading");
			FILE *fd = fopen(tmpfname,"w");
			if (fd == NULL) {
				strerror_r(errno, curl_err,CURL_ERROR_SIZE);
				caml_error(req, errno, curl_err);
				continue;
			}
			
			curl_easy_setopt(curl_hndlr, CURLOPT_URL, req->url);
			curl_easy_setopt(curl_hndlr, CURLOPT_WRITEDATA,fd);

			if (req->prgrssCb) {
				curl_easy_setopt(curl_hndlr, CURLOPT_PROGRESSDATA, (void*)req->prgrssCb);
				curl_easy_setopt(curl_hndlr, CURLOPT_PROGRESSFUNCTION, progress);
				curl_easy_setopt(curl_hndlr, CURLOPT_NOPROGRESS, 0);
			} else {
				curl_easy_setopt(curl_hndlr, CURLOPT_PROGRESSDATA, NULL);
				curl_easy_setopt(curl_hndlr, CURLOPT_PROGRESSFUNCTION, NULL);
				curl_easy_setopt(curl_hndlr, CURLOPT_NOPROGRESS, 1);
			}

			int curl_perform_retval = curl_easy_perform(curl_hndlr);

			fclose(fd);
			if (curl_perform_retval) {
				unlink(tmpfname);
				caml_error(req, curl_perform_retval, curl_err);
			} else {
				long respCode;
				curl_easy_getinfo(curl_hndlr, CURLINFO_RESPONSE_CODE, &respCode);

				 if (respCode != 200) {
				 	caml_error(req, (int)respCode, "http code is not 200");
				 } else {
					PRINT_DEBUG("complete loading %s %ld",req->path, respCode);
					rename(tmpfname, req->path);
					RUN_ON_ML_THREAD(&curl_filedownloader_success, (void*)req);
					*curl_err = '\0';
				 }
			};
			free(tmpfname);
		}
	};
	return NULL;
}

extern void initCurl();

value ml_DownloadFile(value url, value path, value errCb, value prgrssCb, value cb) {
	CAMLparam5(url, path, errCb, prgrssCb, cb);

	initCurl();

	PRINT_DEBUG("START DOWNLOAD FILE");

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

	if (prgrssCb != Val_int(0)) {
		req->prgrssCb = (value*)malloc(sizeof(value));
		*(req->prgrssCb) = Field(prgrssCb, 0);
		caml_register_generational_global_root(req->prgrssCb);
	} else {
		req->prgrssCb = NULL;
	}

	if (!reqs && !(reqs = thqueue_download_reqs_create())) {
		caml_failwith("cannot create requests queue");
	}

	if (!tid && pthread_create(&tid, NULL, &downloader_thread, NULL)) {
		caml_failwith("cannot create loader thread");
	}

	thqueue_download_reqs_push(reqs, req);
	pthread_cond_signal(&cond);

	CAMLreturn(Val_unit);
}
