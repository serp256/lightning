#include "mlwrapper_android.h"

#include "light_common.h"
#include "texture_common.h"
#include "thqueue.h"
#include "net_curl.h"

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

static void caml_error(cel_request_t* req, int errCode, char* errMes) {
	PRINT_DEBUG("caml_error %d %s", errCode, errMes);

	if (req->errCb) {
		PRINT_DEBUG("callback");

		JNIEnv *env;
    	(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);

		static jmethodID curlExtLdrErrorMid;
		if (!curlExtLdrErrorMid) curlExtLdrErrorMid = (*env)->GetMethodID(env, jViewCls, "curlExternalLoaderError", "(III)V");

		char* _errMes = malloc(strlen(errMes) + 1);
		strcpy(_errMes, errMes);
		(*env)->CallVoidMethod(env, jView, curlExtLdrErrorMid, (int)req, errCode, (int)_errMes);		
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
	(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);
	jfieldID wFid;
	jfieldID hFid;
	jfieldID lwFid;
	jfieldID lhFid;
	jfieldID dataFid;
	jfieldID formatFid;    
	jmethodID decodeImgMid = (*env)->GetMethodID(env, jViewCls, "decodeImg", "([B)Lru/redspell/lightning/LightView$TexInfo;");
	jmethodID curlExtLdrSuccessMid = (*env)->GetMethodID(env, jViewCls, "curlExternalLoaderSuccess", "(II)V");

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
			    jobject jtexInfo = (*env)->CallObjectMethod(env, jView, decodeImgMid, src);
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

			    	textureInfo* texInfo = malloc(sizeof(textureInfo));

			    	jstring jformat = (*env)->GetObjectField(env, jtexInfo, formatFid);
			    	const char* cformat = (*env)->GetStringUTFChars(env, jformat, JNI_FALSE);

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

				    (*env)->CallVoidMethod(env, jView, curlExtLdrSuccessMid, (int)req, (int)texInfo);

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
}

void ml_loadExternalImage(value url, value cb, value errCb) {
	initCurl();

	JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

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

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024CurlExternCallbackRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID reqFid;
	static jfieldID texInfoFid;

	if (!reqFid) {
		jclass runnableCls = (*env)->GetObjectClass(env, this);
		reqFid = (*env)->GetFieldID(env, runnableCls, "req", "I");
		texInfoFid = (*env)->GetFieldID(env, runnableCls, "texInfo", "I");
	}

	cel_request_t* req = (cel_request_t*)(*env)->GetIntField(env, this, reqFid);
	textureInfo* texInfo = (textureInfo*)(*env)->GetIntField(env, this, texInfoFid);

	value textureID = createGLTexture(1, texInfo, Val_int(1));
	value mlTex = 0;
	ML_TEXTURE_INFO(mlTex, textureID, texInfo);
	caml_callback(*(req->cb), mlTex);

	free(texInfo->imgData);
	free(texInfo);
	freeRequest(req);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024CurlExternErrorCallbackRunnable_run(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightView_00024CurlExternErrorCallbackRunnable_run");

	static jfieldID reqFid;
	static jfieldID errCodeMid;
	static jfieldID errMesMid;

	if (!reqFid) {
		jclass runnableCls = (*env)->GetObjectClass(env, this);
		reqFid = (*env)->GetFieldID(env, runnableCls, "req", "I");
		errCodeMid = (*env)->GetFieldID(env, runnableCls, "errCode", "I");
		errMesMid = (*env)->GetFieldID(env, runnableCls, "errMes", "I");
	}

	cel_request_t* req = (cel_request_t*)(*env)->GetIntField(env, this, reqFid);
	int errCode = (*env)->GetIntField(env, this, errCodeMid);
	char* errMes = (char*)(*env)->GetIntField(env, this, errMesMid);

	caml_callback2(*(req->errCb), Val_int(errCode), caml_copy_string(errMes));

	free(errMes);
	freeRequest(req);
}
