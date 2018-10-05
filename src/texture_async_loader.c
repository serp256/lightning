
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "thqueue.h"
#include "light_common.h"
#include "texture_common.h"

#include "caml/memory.h"
#include "caml/mlvalues.h"
#include "caml/alloc.h"
#include "caml/fail.h"

#ifdef IOS
#include "ios/texture_ios.h"
#elif ANDROID
#include "android/texture_android.h"
#include "engine_android.h"
#include "lightning_android.h"
#else
#include "sdl/texture_sdl.h"
#endif

typedef struct {
	char *path;
	char *suffix;
	value filter;
	int use_pvr;
} request_t;

typedef struct {
	char *path;
	unsigned char with_suffix;
	value filter;
	textureInfo* tInfo;
	textureInfo* alphaTexInfo;
} response_t;

THQUEUE_INIT(requests,request_t*)
THQUEUE_INIT(responses,response_t*)

typedef struct {
	thqueue_requests_t *req_queue;
	thqueue_responses_t *resp_queue;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	pthread_t worker;
} runtime_t;


static void *run_worker(void *param) {
	runtime_t *runtime = (runtime_t*)param;
	pthread_mutex_lock(&(runtime->mutex));
	while (1) {
		request_t *req = thqueue_requests_pop(runtime->req_queue);
		if (req == NULL) pthread_cond_wait(&(runtime->cond),&(runtime->mutex));
		else {
            /*
			PRINT_DEBUG("texture run worker %s", req->path);

			textureInfo *tInfo = (textureInfo*)malloc(sizeof(textureInfo));

			int r = load_image_info(req->path,req->suffix,req->use_pvr,tInfo);
			if (r) {
				free(tInfo);
				if (r == 2) ERROR("ASYNC LOADER. Can't find %s\n",req->path);
				else ERROR("Can't load image %s\n",req->path);
				tInfo = NULL;
			}

			PRINT_DEBUG("create response");

			response_t *resp = malloc(sizeof(response_t));
			resp->path = req->path; 
			resp->with_suffix = (req->suffix != NULL);
			resp->filter = req->filter;
			resp->tInfo = tInfo;
			resp->alphaTexInfo = NULL;

			PRINT_DEBUG("ok");

			if (!r) {
				resp->alphaTexInfo = loadCmprsAlphaTex(tInfo, req->path, req->suffix, req->use_pvr);	
			}
			
			PRINT_DEBUG("free suffix");
			if (req->suffix != NULL) free(req->suffix); free(req);
			thqueue_responses_push(runtime->resp_queue,resp);
            */
			PRINT_DEBUG("response pushed");
		}
	}
}

value ml_texture_async_loader_create_runtime(value unit) {

	runtime_t *runtime = (runtime_t*)malloc(sizeof(runtime_t));
	runtime->req_queue = thqueue_requests_create();
	runtime->resp_queue = thqueue_responses_create();
	pthread_mutex_init(&(runtime->mutex),NULL);
	pthread_cond_init(&(runtime->cond),NULL);

  pthread_attr_t attr;
  pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_DETACHED);
	//pthread_attr_setschedpolicy
  pthread_create(&runtime->worker, &attr, &run_worker, (void*)runtime);

	return((value)runtime);

}

value ml_texture_async_loader_push(value oruntime,value opath,value osuffix,value filter, value use_pvr) {
	char *path = malloc(caml_string_length(opath) + 1);
	strcpy(path,String_val(opath));
	char *suffix;
	if (Is_block(osuffix)) {
		suffix = malloc(caml_string_length(Field(osuffix,0)) + 1);
		strcpy(suffix,String_val(Field(osuffix,0)));
	}  else suffix = NULL;
	//fprintf(stderr,"REQUEST TO LOAD %s[%s]\n",path,suffix);
	runtime_t *runtime = (runtime_t*)oruntime;
	request_t *req = malloc(sizeof(request_t));
	req->path = path;
	req->suffix = suffix;
	req->filter = filter;
	req->use_pvr = Bool_val(use_pvr);

    //перенес определение информации из run_worker (который сейчас по факту ничего не делает) так как нельзя вызывать методы из явы вне главного потока
			textureInfo *tInfo = (textureInfo*)malloc(sizeof(textureInfo));

			int r = load_image_info(req->path,req->suffix,req->use_pvr,tInfo);
			if (r) {
				free(tInfo);
				if (r == 2) ERROR("ASYNC LOADER. Can't find %s\n",req->path);
				else ERROR("Can't load image %s\n",req->path);
				tInfo = NULL;
			}

			PRINT_DEBUG("create response");

			response_t *resp = malloc(sizeof(response_t));
			resp->path = req->path; 
			resp->with_suffix = (req->suffix != NULL);
			resp->filter = req->filter;
			resp->tInfo = tInfo;
			resp->alphaTexInfo = NULL;

			PRINT_DEBUG("ok");

			if (!r) {
				resp->alphaTexInfo = loadCmprsAlphaTex(tInfo, req->path, req->suffix, req->use_pvr);	
			}
			
			PRINT_DEBUG("free suffix");
			if (req->suffix != NULL) free(req->suffix); free(req);

			thqueue_responses_push(runtime->resp_queue,resp);

	//thqueue_requests_push(runtime->req_queue,req);
	pthread_cond_signal(&runtime->cond);

	return Val_unit;
}


value ml_texture_async_loader_pop(value oruntime) {
	CAMLparam0();
	CAMLlocal5(res,opath,mlTex,mlAlphaTex, block);
	runtime_t *runtime = (runtime_t*)oruntime;
	response_t *r = thqueue_responses_pop(runtime->resp_queue);
	if (r == NULL) res = Val_unit;
	else {
		PRINT_DEBUG("ml_texture_async_loader_pop %s %d", r->path, (int)r->alphaTexInfo);

		if (r->tInfo != NULL) {
			value textureID = createGLTexture(1,r->tInfo,r->filter);
			if (!textureID) caml_failwith("failed to create texture");
			ML_TEXTURE_INFO(mlTex,textureID,r->tInfo);

			if (r->alphaTexInfo) {
				value alphaTexId = createGLTexture(1, r->alphaTexInfo, r->filter);
				ML_TEXTURE_INFO(mlAlphaTex, alphaTexId, r->alphaTexInfo);

				block = caml_alloc(1, 1);
				Store_field(block, 0, mlAlphaTex);
				Store_field(mlTex, 0, block);

				free(r->alphaTexInfo->imgData);
				free(r->alphaTexInfo);
			}
			
			free(r->tInfo->imgData);
			free(r->tInfo);
			value tInfo = caml_alloc_small(1,0);
			Field(tInfo,0) = mlTex;

			mlTex = tInfo;
		} else mlTex = Val_unit;
		opath = caml_copy_string(r->path);
		//fprintf(stderr,"path: %s, suffix: %hhu\n",r->path,r->with_suffix);
		free(r->path);
		res = caml_alloc_tuple(1);
		Store_field(res,0,caml_alloc_small(3,0));
		Field(Field(res,0),0) = opath;
		Field(Field(res,0),1) = Val_bool(r->with_suffix);
		Field(Field(res,0),2) = mlTex;

		free(r);
	};
	CAMLreturn(res);
}
