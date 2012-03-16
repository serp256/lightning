
#include "thqueue.h"
#include "texture_common.h"

#include "caml/memory.h"
#include "caml/mlvalues.h"
#include "caml/alloc.h"
#include "caml/fail.h"

#ifdef IOS
#include "ios/texture_ios.h"
#else
#include "sdl/texture_sdl.h"
#endif


typedef struct {
	char *path;
	textureInfo *tInfo;
} response_t;

THQUEUE_INIT(requests,char*)
THQUEUE_INIT(responses,response_t*)

typedef struct {
	thqueue_requests_t *req_queue;
	thqueue_responses_t *resp_queue;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	pthread_t worker;
} runtime_t;


void *run_worker(void *param) {
	runtime_t *runtime = (runtime_t*)param;
	pthread_mutex_lock(&(runtime->mutex));
	while (1) {
		char *path = thqueue_requests_pop(runtime->req_queue);
		if (path == NULL) pthread_cond_wait(&(runtime->cond),&(runtime->mutex));
		else {
			textureInfo *tInfo = (textureInfo*)malloc(sizeof(textureInfo));
			int r = load_image_info(path,tInfo);// Как тут ебнуца то ?? 
			if (r) {
				free(tInfo);
				if (r == 2) fprintf(stderr,"ASYNC LOADER. Can't find %s\n",path);
				else fprintf(stderr,"Can't load image %s\n",path);
				exit(3);
			};
			response_t *resp = malloc(sizeof(response_t));
			resp->path = path; resp->tInfo = tInfo;
			thqueue_responses_push(runtime->resp_queue,resp);
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
  pthread_create(&runtime->worker, &attr, &run_worker, (void*)runtime);

	return((value)runtime);// может быть стоило финализер повесить ?

}

void ml_texture_async_loader_push(value oruntime,value opath) {
	char *path = malloc(caml_string_length(opath) + 1);
	strcpy(path,String_val(opath));
	runtime_t *runtime = (runtime_t*)oruntime;
	thqueue_requests_push(runtime->req_queue,path);
	pthread_cond_signal(&runtime->cond);
}


value ml_texture_async_loader_pop(value oruntime) {
	CAMLparam0();
	CAMLlocal3(res,opath,mlTex);
	runtime_t *runtime = (runtime_t*)oruntime;
	response_t *r = thqueue_responses_pop(runtime->resp_queue);
	if (r == NULL) res = Val_unit;
	else {
		GLuint textureID = createGLTexture(0,r->tInfo);
		if (!textureID) caml_failwith("failed to load texture");
		ML_TEXTURE_INFO(mlTex,textureID,r->tInfo);
		free(r->tInfo->imgData);
		free(r->tInfo);
		opath = caml_copy_string(r->path);
		free(r->path);
		res = caml_alloc_tuple(1);
		Store_field(res,0,caml_alloc_small(2,0));
		Field(Field(res,0),0) = opath;
		Field(Field(res,0),1) = mlTex;
	};
	CAMLreturn(res);
}
