
#include "thqueue.h"
#include "texture_common.h"


typedef struct {
	char *path;
	textureInfo *tInfo;
} response;

THQUEUE_INIT(requests,char*)
THQUEUE_INIT(responses,response*)

typedef struct {
	thqueue_requests_t *req_queue;
	thqueue_responses_t *resp_queue;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	pthread_t worker;
} runtime_t;


void run_worker(void *param) {
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
			response *resp = malloc(sizeof(response));
			resp->path = path; resp->tInfo = tInfo;
			thqueue_responses_push(runtime->resp_queue,resp);
		}
	}
}

value ml_create_runtime() {

	runtime_t runtime = (runtime_t*)malloc(sizeof(runtime_t));
	runtime->req_queue = thqueue_requests_create();
	runtime->resp_queue = thqueue_responses_create();
	pthread_mutex_init(&(runtime->mutex),NULL);
	pthread_cond_init(&(runtime->cond),NULL);

  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_create(&runtime->worker, &attr, &run_worker, NULL);

	return((value)runtime);// может быть стоило финализер повесить ?

}

void ml_texture_load_async_push(value oruntime,value opath) {
	char *path = malloc(caml_string_length(opath) + 1);
	strcpy(path,String_val(opath));
	runtime_t *runtime = (runtime_t*)oruntime;
	thqueue_requests_push(runtime->req_queue,path);
	pthread_cond_signal(&runtime->cond);
}


value ml_texture_load_async_pop(value unit) {
	if (runtime != NULL) return Val_unit;
}
