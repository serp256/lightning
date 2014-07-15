#include "lightning_android.h"
#include "engine.h"

#include "light_common.h"
#include "texture_common.h"
#include "thqueue.h"

#include "caml/mlvalues.h"
#include "caml/memory.h"

#ifdef ANDROID
#define CURL_DISABLE_TYPECHECK
#include "android/libcurl/curl.h"
#else
#include <curl/curl.h>
#endif

#define MIN_ALLOC_SIZE 4096

typedef struct {
	char* url;
	value* cb;
	value* errCb;
} cel_request_t;

THQUEUE_INIT(cel_reqs,cel_request_t*);

static pthread_mutex_t mutex;
static pthread_cond_t cond;
static pthread_t tid;
static thqueue_cel_reqs_t* reqs;

static char* buf;
static size_t buf_len = 0;
static size_t buf_pos = 0;

static size_t curl_wfunc(char *ptr, size_t size, size_t nmemb, void *userdata) {
	size_t chunk_len = size * nmemb;
	size_t free_space = buf_len - buf_pos;

	PRINT_DEBUG("buf_len: %d, buf_pos: %d", buf_len, buf_pos);
	PRINT_DEBUG("chunk_len: %d, free_space: %d", chunk_len, free_space);

	if (free_space < chunk_len) {
		size_t realloc_size = chunk_len - free_space;
		if (realloc_size < MIN_ALLOC_SIZE) realloc_size = MIN_ALLOC_SIZE;

		PRINT_DEBUG("need realloc %d", realloc_size);

		buf = realloc(buf, buf_len + realloc_size);
		buf_len += realloc_size;

		PRINT_DEBUG("new buf len %d", buf_len);
	} else {
		PRINT_DEBUG("no need in realloc");
	}
	
	memcpy(buf + buf_pos, ptr, chunk_len);
	buf_pos += chunk_len;

	PRINT_DEBUG("new buf pos %d", buf_pos);

	return chunk_len;
}

static void freeRequest(cel_request_t* req) {
	caml_remove_generational_global_root(req->cb);

	if (req->errCb) {
		caml_remove_generational_global_root(req->errCb);
		free(req->errCb);
	}

	free(req->url);
	free(req->cb);	
	free(req);
}

typedef struct {
	cel_request_t *req;
	textureInfo *tex_inf;
} curl_loader_success_t;


typedef struct {
	cel_request_t *req;
	int err_code;
	char *err_mes;
} curl_loader_error_t;

void curl_loader_success(void *data) {
	curl_loader_success_t *success = (curl_loader_success_t*)data;

	value textureID = createGLTexture(1, success->tex_inf, Val_int(1));
	value mlTex = 0;
	ML_TEXTURE_INFO(mlTex, textureID, success->tex_inf);
	caml_callback(*(success->req->cb), mlTex);

	free(success->tex_inf->imgData);
	free(success->tex_inf);
	freeRequest(success->req);
	free(success);
}

void curl_loader_error(void *data) {
	curl_loader_error_t *error = (curl_loader_error_t*)data;

	caml_callback2(*(error->req->errCb), Val_int(error->err_code), caml_copy_string(error->err_mes));

	free(error->err_mes);
	freeRequest(error->req);
	free(error);
}

static void caml_error(cel_request_t* req, int errCode, char* errMes) {
	PRINT_DEBUG("caml_error %d %s", errCode, errMes);

	if (req->errCb) {
		PRINT_DEBUG("callback");

		curl_loader_error_t *error = (curl_loader_error_t*)malloc(sizeof(curl_loader_error_t));
		error->req = req;
		error->err_code = errCode;
		error->err_mes = errMes;
		RUN_ON_ML_THREAD(&curl_loader_error, error);
	}
}

static void* loader_thread(void* params) {
	pthread_mutex_lock(&mutex);

	CURL* curl_hndlr = curl_easy_init();
	char* curl_err = (char*)malloc(CURL_ERROR_SIZE);
	curl_easy_setopt(curl_hndlr, CURLOPT_ERRORBUFFER, curl_err);
	curl_easy_setopt(curl_hndlr, CURLOPT_WRITEFUNCTION, curl_wfunc);
	curl_easy_setopt(curl_hndlr, CURLOPT_FOLLOWLOCATION, 1);

	JNIEnv *env;
	(*VM)->AttachCurrentThread(VM, &env, NULL);
	static jfieldID wFid = 0;
	static jfieldID hFid;
	static jfieldID lwFid;
	static jfieldID lhFid;
	static jfieldID dataFid;
	static jfieldID formatFid;

	jmethodID decode_mid = (*env)->GetStaticMethodID(env, lightning_cls, "decodeImg", "([B)Lru/redspell/lightning/v2/Lightning$TexInfo;");
	// jmethodID curlExtLdrSuccessMid = (*env)->GetMethodID(env, jViewCls, "curlExternalLoaderSuccess", "(II)V");

	while (1) {
		cel_request_t* req = thqueue_cel_reqs_pop(reqs);

		if (!req) {
			PRINT_DEBUG("waiting...");
			pthread_cond_wait(&cond, &mutex);
		} else {
			PRINT_DEBUG("loading %s...", req->url);
			
			curl_easy_setopt(curl_hndlr, CURLOPT_URL, req->url);
			int curl_perform_retval = curl_easy_perform(curl_hndlr);

			if (curl_perform_retval) {
				caml_error(req, curl_perform_retval, curl_err);
			} else {
				PRINT_DEBUG("complete");				

			    jbyteArray src = (*env)->NewByteArray(env, buf_pos);
			    (*env)->SetByteArrayRegion(env, src, 0, buf_pos, (jbyte*)buf);
			    PRINT_DEBUG("call decode");
			    jobject jtexInfo = (*env)->CallStaticObjectMethod(env, lightning_cls, decode_mid, src);
				(*env)->DeleteLocalRef(env,src);

			    PRINT_DEBUG("jtexInfo %d", jtexInfo);

			    if (jtexInfo) {
			    	
				    if (!wFid) {
				    	jclass texInfoCls = (*env)->GetObjectClass(env, jtexInfo);
				    	PRINT_DEBUG("texInfoCls %d", texInfoCls);

					    wFid = (*env)->GetFieldID(env, texInfoCls, "width", "I");
					    hFid = (*env)->GetFieldID(env, texInfoCls, "height", "I");
					    lwFid = (*env)->GetFieldID(env, texInfoCls, "legalWidth", "I");
					    lhFid = (*env)->GetFieldID(env, texInfoCls, "legalHeight", "I");
					    dataFid = (*env)->GetFieldID(env, texInfoCls, "data", "[B");
					    formatFid = (*env)->GetFieldID(env, texInfoCls, "format", "Ljava/lang/String;");

					    (*env)->DeleteLocalRef(env, texInfoCls);
				    }

						PRINT_DEBUG("after static init");

			    	textureInfo* texInfo = malloc(sizeof(textureInfo));

						PRINT_DEBUG("after malloc");

			    	jstring jformat = (*env)->GetObjectField(env, jtexInfo, formatFid);

						PRINT_DEBUG("JFORMAT %d", jformat);

			    	const char* cformat = (*env)->GetStringUTFChars(env, jformat, JNI_FALSE);

			    	PRINT_DEBUG("!!!FORMAT %s", cformat);

			    	if (!strcmp(cformat, "ALPHA_8")) texInfo->format = LTextureFormatAlpha;
			    	else if (!strcmp(cformat, "ARGB_4444")) texInfo->format = LTextureFormat4444;
			    	else if (!strcmp(cformat, "ARGB_8888")) texInfo->format = LTextureFormatRGBA;
			    	else if (!strcmp(cformat, "RGB_565")) texInfo->format = LTextureFormat565;

			    	(*env)->ReleaseStringUTFChars(env, jformat, cformat);

						(*env)->DeleteLocalRef(env,jformat);

			    	texInfo->width = (*env)->GetIntField(env, jtexInfo, lwFid);
			    	texInfo->height = (*env)->GetIntField(env, jtexInfo, lhFid);
			    	texInfo->realWidth = (*env)->GetIntField(env, jtexInfo, wFid);
			    	texInfo->realHeight = (*env)->GetIntField(env, jtexInfo, hFid);
						texInfo->generateMipmaps = 0;
						texInfo->numMipmaps = 0;
						texInfo->premultipliedAlpha = 0;
						texInfo->scale = 1.0f;

			    	jbyteArray jdata = (*env)->GetObjectField(env, jtexInfo, dataFid);
			    	size_t bmp_bytes_len = (*env)->GetArrayLength(env, jdata);
				    jbyte* cdata = (*env)->GetByteArrayElements(env, jdata, JNI_FALSE);

				    texInfo->dataLen = bmp_bytes_len;
				    texInfo->imgData = malloc(bmp_bytes_len);
				    memcpy(texInfo->imgData, cdata, bmp_bytes_len);

				    (*env)->ReleaseByteArrayElements(env, jdata, cdata, 0);
				    (*env)->DeleteLocalRef(env, jdata);
						(*env)->DeleteLocalRef(env,jtexInfo);

					curl_loader_success_t *success = (curl_loader_success_t*)malloc(sizeof(curl_loader_success_t));
					success->req = req;
					success->tex_inf = texInfo;
					RUN_ON_ML_THREAD(&curl_loader_success, success);						

					PRINT_DEBUG("after success call");
			    } else {
			    	caml_error(req, 100, "cannot parse image binary");
			    }

				free(buf);
				buf = NULL;
				buf_pos = 0;
				buf_len = 0;
				*curl_err = '\0';				
			}
		}
	}

	return NULL;
}

extern void initCurl();

value ml_loadExternalImage(value url, value cb, value errCb) {
	initCurl();

	PRINT_DEBUG("LOAD EXTERNAL IMAGE");
	cel_request_t* req = (cel_request_t*)malloc(sizeof(cel_request_t));

	req->url = (char*)malloc(caml_string_length(url) + 1);
	strcpy(req->url, String_val(url));

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

	if (!reqs && !(reqs = thqueue_cel_reqs_create())) {
		caml_failwith("cannot create requests queue");
	}

	if (!tid && pthread_create(&tid, NULL, &loader_thread, NULL)) {
		caml_failwith("cannot create loader thread");
	}

	thqueue_cel_reqs_push(reqs, req);
	pthread_cond_signal(&cond);

	return Val_unit;
}
