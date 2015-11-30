#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "light_common.h"
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include <caml/memory.h>
//
//
//
#ifdef ANDROID
#define CURL_DISABLE_TYPECHECK
#include "android/libcurl/curl.h"
#else
#include <curl/curl.h>
#endif



/// ADD THREAD NOW!!!!!

void initCurl() {
	static int init;

	if (!init) {
		curl_global_init(CURL_GLOBAL_SSL);
		init = 1;
	}
}


#include "thqueue.h"

// static  = NULL;

typedef struct {
	CURL *handle;
	char *url;
	struct curl_slist *headers;
	char *data;
	int headers_done;
	void *resp_queue;

	int complete;
	int canceled;
	// we need canceled_resp_pushed flag cause it's possible, that canceled flag will be setted before add request will be handled, therefore cancel response
	// will be pushed to queue twice and app will crash when trying to handle second cancel response (trying to free already freed request structure)
	int canceled_resp_pushed;
} request_t;

/*
	может получиться так, что мы взвели canceled до того, как обработался реквест на добавление запроса в run_worker,
	соотвественно при обработка запросов canceled уже взведен и в очереди будут два фейковых calcel-респонза, соотвественно
	будет попытка освободить уже освобожденный реквест в net_run

	соотвественно нужен ещё флажок
*/


////////////////////////////

typedef struct {
	long http_code;
	int64_t content_length;
	char *content_type;
} response_header;

typedef struct {
	size_t len;
	char *data;
} response_data;

typedef struct response_el response_el;

struct response_el {
	int ev;
	response_el* next;

	union {
		response_header header;
		response_data data;
	} content;
};

enum {
	RHEADER = 1,
	RDATA = 1 << 2,
	RCOMPLETE = 1 << 3,
	RERROR = 1 << 4,
	RCANCELED = 1 << 5
};


typedef struct {
	request_t* req;
	response_el *events;
} response_t;


THQUEUE_INIT(url_ldr_req,request_t*)
THQUEUE_INIT(url_ldr_resp,response_t*)


typedef struct {
	CURLM *curlm;
	thqueue_url_ldr_req_t *req_queue;
	thqueue_url_ldr_resp_t *resp_queue;
	int net_running;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	pthread_t worker;
} runtime_t;




static response_el* get_header(request_t *r) {
	response_el *p = (response_el*)malloc(sizeof(response_el));
	p->ev = RHEADER;
	response_header *h = &p->content.header;
	curl_easy_getinfo(r->handle,CURLINFO_RESPONSE_CODE,&h->http_code);

	double content_length;
	curl_easy_getinfo(r->handle,CURLINFO_CONTENT_LENGTH_DOWNLOAD,&content_length);
	h->content_length = (int64_t)content_length;

	char *content_type;
	curl_easy_getinfo(r->handle,CURLINFO_CONTENT_TYPE,&content_type);
	if (content_type != NULL) {
		size_t len = strlen(content_type);
		h->content_type = malloc(len+1);
		strcpy(h->content_type,content_type);
	}
	else h->content_type = NULL;

	p->next = NULL;
	r->headers_done = 1;
	return p;
}

static size_t my_writefunction(char *buffer,size_t size,size_t nitems, void *p) {
	request_t *req = (request_t*)p;
	PRINT_DEBUG("writefunction %lu",(long)req);
	response_t *resp = (response_t*)malloc(sizeof(response_t));
	resp->req = req;
	response_el **ev = &resp->events;

	if (!req->headers_done) {
		response_el *hp = get_header(req);
		*ev = hp;
		ev = &hp->next;
	}

	size_t s = size * nitems;
	response_el *evd = (response_el*)malloc(sizeof(response_el));
	evd->ev = RDATA;
	evd->content.data.len = s;
	if (s > 0) {
		evd->content.data.data = malloc(s);
		memcpy(evd->content.data.data,buffer,s);
	}
	evd->next = NULL;
	*ev = evd;
	thqueue_url_ldr_resp_push((thqueue_url_ldr_resp_t*)(req->resp_queue),resp);

	return s;
}


static void *run_worker(void *param) {
	PRINT_DEBUG("run_worker");

	runtime_t *runtime = (runtime_t*)param;
	pthread_mutex_lock(&(runtime->mutex));
	struct timeval timeout;
	int rc; /* select() return code */
	while (1) {

		PRINT_DEBUG("while 1:1");
		while (1) {
			PRINT_DEBUG("while 1:2");
			request_t *req = thqueue_url_ldr_req_pop(runtime->req_queue);
			PRINT_DEBUG("req %d", req);
			if (req != NULL) {
				PRINT_DEBUG("req->canceled %d", req->canceled);

				PRINT_DEBUG ("1 net_running %d", runtime->net_running);
				if (!req->canceled) {
					PRINT_DEBUG("add req");
					curl_multi_add_handle(runtime->curlm, req->handle);
					req->resp_queue = runtime->resp_queue;
					runtime->net_running++;
					PRINT_DEBUG ("2 net_running %d", runtime->net_running);
				} else {
					PRINT_DEBUG("req->complete %d; req->canceled %d; req->canceled_resp_puched %d", req->complete, req->canceled, req->canceled_resp_pushed);
					if (!req->complete && !req->canceled_resp_pushed) {
						req->canceled_resp_pushed = 1;
						curl_multi_remove_handle(runtime->curlm, req->handle);
						runtime->net_running--;
						runtime->net_running =(runtime->net_running < 0) ? 0 : runtime->net_running;
						PRINT_DEBUG ("3 net_running %d", runtime->net_running);

						response_el *ev = (response_el*)malloc(sizeof(response_el));
						ev->ev = RCANCELED;
						ev->next = NULL;

						response_t *resp = (response_t*)malloc(sizeof(response_t));
						resp->req = req;
						resp->events = ev;
						thqueue_url_ldr_resp_push(runtime->resp_queue, resp);
					}
				}
			} else 
			{
				PRINT_DEBUG ("req=null, break");
				break;
			}
		};

		if (runtime->net_running <= 0) {
				PRINT_DEBUG ("net_running %d", runtime->net_running);
				pthread_cond_wait(&(runtime->cond),&(runtime->mutex));
		}
		else {
				PRINT_DEBUG ("net_running %d", runtime->net_running);
			fd_set fdread;
		    fd_set fdwrite;
		    fd_set fdexcep;
		    int maxfd = -1;
		    long curl_timeo = -1;
		    FD_ZERO(&fdread);
		    FD_ZERO(&fdwrite);
		    FD_ZERO(&fdexcep);

			/* set a suitable timeout to play around with */
		    timeout.tv_sec = 0;
		    timeout.tv_usec = 300000;

			curl_multi_timeout(runtime->curlm, &curl_timeo);
		    if(curl_timeo >= 0 && curl_timeo < 300) {
					timeout.tv_usec = curl_timeo * 1000;
		    }

		    /* get file descriptors from the transfers */
		    curl_multi_fdset(runtime->curlm, &fdread, &fdwrite, &fdexcep, &maxfd);
			//TODO: check return value and fail error

	    /* In a real-world program you OF COURSE check the return code of the
	       function calls.  On success, the value of maxfd is guaranteed to be
	       greater or equal than -1.  We call select(maxfd + 1, ...), specially in
	       case of (maxfd == -1), we call select(0, ...), which is basically equal
	       to sleep. */

	       	// PRINT_DEBUG("waiting on select...");
			rc = select(maxfd+1, &fdread, &fdwrite, &fdexcep, &timeout);
			// PRINT_DEBUG("fall out select");
			//TODO: check return value and fail error

			int running_handles;
			int r = curl_multi_perform(runtime->curlm,&running_handles);
			if (r != CURLM_OK && r != CURLM_CALL_MULTI_PERFORM) {
				const char *err = curl_multi_strerror(r);
				ERROR("curl error: %s",err);
				exit(3); // ?????
				//TODO: fail error
			}

			PRINT_DEBUG("running_handles %d, running_handles %d", running_handles, runtime->net_running);

			if (running_handles < runtime->net_running) { // we need check info
				runtime->net_running = running_handles;
				CURLMsg *msg; /* for picking up messages with the transfer status */
				int msgs_left; /* how many messages are left */
				CURL *c;
				while ((msg = curl_multi_info_read(runtime->curlm, &msgs_left))) {
					if (msg->msg == CURLMSG_DONE) {
						c = msg->easy_handle;
						request_t *r = NULL;
						curl_easy_getinfo(c,CURLINFO_PRIVATE,&r);
						PRINT_DEBUG("url_loader complete: %lu",(long)r);
						PRINT_DEBUG("msg->data.result: %u", msg->data.result);
						response_t *resp = (response_t*)malloc(sizeof(response_t));
						resp->req = r;
						r->complete = 1;
						// вызвать окамл и все похерить нахуй
						if (msg->data.result == CURLE_OK) {
							PRINT_DEBUG("msg->data.result == CURLE_OK");

							response_el **ev = &resp->events;
							if (!r->headers_done) {
								response_el *hev = get_header(r);
								*ev = hev;
								ev = &hev->next;
							}
							response_el *cev = (response_el*)malloc(sizeof(response_el));
							cev->ev = RCOMPLETE;
							cev->next = NULL;
							*ev = cev;
						} else {
							PRINT_DEBUG("msg->data.result error");

							const char* emsg = curl_easy_strerror(msg->data.result);
							// we need to clean up this string or it's curl owned string ????
							response_el *eev = (response_el*)malloc(sizeof(response_el));
							eev->ev = RERROR;
							eev->next = NULL;
							eev->content.data.len = msg->data.result;
							eev->content.data.data = (char*)emsg;
							resp->events = eev;
						};
						curl_multi_remove_handle(runtime->curlm,c);
						// curl_easy_cleanup(c);
						thqueue_url_ldr_resp_push(runtime->resp_queue,resp);
					}
				}
			}
		}
	}
}

static runtime_t *runtime = NULL;

int net_running() {
	return !runtime ? 0 : runtime->net_running;
}

static void init() {
	PRINT_DEBUG ("init");

	initCurl();

	runtime = (runtime_t*)malloc(sizeof(runtime_t));
	runtime->curlm = curl_multi_init();
	runtime->req_queue = thqueue_url_ldr_req_create();
	runtime->resp_queue = thqueue_url_ldr_resp_create();
	runtime->net_running = 0;
	pthread_mutex_init(&(runtime->mutex),NULL);
	pthread_cond_init(&(runtime->cond),NULL);

	pthread_attr_t attr;
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_DETACHED);
	pthread_create(&runtime->worker, &attr, &run_worker, (void*)runtime);
	PRINT_DEBUG ("init completed");
}


CAMLprim value ml_URLConnection(value url, value method, value headers, value data) {
	PRINT_DEBUG("ml_URLConnection");
	PRINT_DEBUG("%s", curl_version());

	if (runtime == NULL) init ();

	runtime->net_running =(runtime->net_running < 0) ? 0 : runtime->net_running;

	request_t *r = (request_t*)caml_stat_alloc(sizeof(request_t));
	r->canceled = 0;
	r->canceled_resp_pushed = 0;
	r->complete = 0;
	r->handle = curl_easy_init();
	r->url = strdup(String_val(url));
	PRINT_DEBUG("curl req: [%s]",r->url);
	curl_easy_setopt(r->handle,CURLOPT_URL,r->url);
	curl_easy_setopt(r->handle, CURLOPT_ACCEPT_ENCODING, "");
	static value ml_POST = 0;
	if (ml_POST == 0) ml_POST = caml_hash_variant("POST");
	if (method == ml_POST) {PRINT_DEBUG("this is POST"); curl_easy_setopt(r->handle,CURLOPT_POST,1);} else PRINT_DEBUG("GET!!!!");
	r->headers = NULL;
	if (Is_block(headers)) {
		value h = headers;
		char *name,*val,*header;
		size_t nlen,vlen;
		do {
			name = String_val(Field(Field(h,0),0));
			val = String_val(Field(Field(h,0),1));
			PRINT_DEBUG("header [%s = %s]",name,val);
			nlen = strlen(name);
			vlen = strlen(val);
			header = (char*)caml_stat_alloc(nlen+vlen+2);
			strcpy(header,name);
			header[nlen] = ':';
			strcpy(header + nlen + 1,val);
			r->headers = curl_slist_append(r->headers,header);
			h = Field(h,1);
		} while (Is_block(h));
		curl_easy_setopt(r->handle,CURLOPT_HTTPHEADER,r->headers);
	}
	r->headers_done = 0;
	if (Is_block(data)) {
		value d = Field(data,0);
		size_t l = caml_string_length(d);
		PRINT_DEBUG("send data of len: %d",l);
		r->data = (char*)malloc(l);
		memcpy(r->data,String_val(d),l);
		curl_easy_setopt(r->handle,CURLOPT_POSTFIELDS,r->data);
		curl_easy_setopt(r->handle,CURLOPT_POSTFIELDSIZE,l);
	} else r->data = NULL;
	//curl_easy_setopt(r->handle,CURLOPT_HEADERFUNCTION,&my_headerfunction);
	curl_easy_setopt(r->handle,CURLOPT_WRITEFUNCTION,&my_writefunction);
	curl_easy_setopt(r->handle,CURLOPT_WRITEDATA,(void*)r);
	curl_easy_setopt(r->handle,CURLOPT_PRIVATE,(void*)r);
	curl_easy_setopt(r->handle,CURLOPT_SSL_VERIFYPEER,0);
	thqueue_url_ldr_req_push(runtime->req_queue,r);
	PRINT_DEBUG("pthread_cond_signal");
	pthread_cond_signal(&runtime->cond);
	PRINT_DEBUG("created new curl request: %lu",(long)r);
	return (value)r;
}

value ml_URLConnection_cancel(value r) {
	PRINT_DEBUG("ml_URLConnection_cancel call");
	request_t* req = (request_t*)r;
	PRINT_DEBUG("cancel req %d", req);
	req->canceled = 1;
	thqueue_url_ldr_req_push(runtime->req_queue, req);
/*	PRINT_DEBUG("ml_URLConnection_cancel call %d %d", runtime->net_running, r);

	if (!runtime->net_running || !runtime->curlm) {
		PRINT_DEBUG("return");
		return;
	}

	request_t* req = (request_t*)r;
	curl_multi_remove_handle(runtime->curlm, req->handle);
	curl_easy_cleanup(req->handle);
	free_request(req);

	runtime->net_running--;

	PRINT_DEBUG("net_running %d", runtime->net_running);*/
	return Val_unit;
}



////////////////////
/// thread this ///

#define CAML_NAMED_VALUE(name) static value* ml_ ## name = NULL; if (ml_ ## name == NULL) ml_ ## name = caml_named_value(#name);

void net_run () {
	if (!runtime) return;

	response_t* resp;

	while (resp = thqueue_url_ldr_resp_pop(runtime->resp_queue)) {
		PRINT_DEBUG("responses");

		request_t* req = resp->req;
		response_el* ev = resp->events;

		int free_req = 0;

		while (ev) {
			switch (ev->ev) {
				case RHEADER: {
					PRINT_DEBUG("RHEADER");
					CAML_NAMED_VALUE(url_response)
					response_header* hdr = &ev->content.header;
					// static value* ml_url_response = NULL; if (ml_url_response == NULL) ml_url_response = caml_named_value("url_response");

					if (!req->canceled) {
						value args[4];
						args[0] = (value)req;
						args[1] = Val_int(hdr->http_code);
						args[2] = caml_copy_int64(hdr->content_length);
						args[3] = caml_copy_string(hdr->content_type ? hdr->content_type : "unknown");
						caml_callbackN(*ml_url_response,4,args);
					}

					free(hdr->content_type);

					break;
				}


				case RDATA: {
					PRINT_DEBUG("RDATA");
					CAML_NAMED_VALUE(url_data)

					if (!req->canceled) {
						value vdata = caml_alloc_string(ev->content.data.len);
						memcpy(String_val(vdata), ev->content.data.data, ev->content.data.len);
						caml_callback2(*ml_url_data,(value)req, vdata);
					}

					free(ev->content.data.data);

					break;
				}

				case RCOMPLETE: {
					PRINT_DEBUG("RCOMPLETE");
					CAML_NAMED_VALUE(url_complete)

					if (!req->canceled) {
						caml_callback(*ml_url_complete,(value)req);
					}

					free_req = 1;

					break;
				}

				case RERROR: {
					PRINT_DEBUG("RERROR");
					CAML_NAMED_VALUE(url_failed)

					if (!req->canceled) {
						caml_callback3(*ml_url_failed,(value)req,Val_int(ev->content.data.len), caml_copy_string(ev->content.data.data));
					}

					free_req = 1;

					break;
				}

				case RCANCELED: {
					PRINT_DEBUG("RCANCELED");
					free_req = 1;
					break;
				}
			}

			response_el* next = ev->next;
			free(ev);
			ev = next;
		}

		free(resp);

		if (free_req) {
			PRINT_DEBUG("freeing request");
			free(req->url);
			free(req->data);
			curl_slist_free_all(req->headers);
			curl_easy_cleanup(req->handle);
			free(req);
		}
	}

	// нужно пробовать вычитвать ебучие ответы
/*	if (!runtime) return;

	static value *ml_url_response = NULL;

	if (ml_url_response == NULL) ml_url_response = caml_named_value("url_response");
	else ml_string = caml_alloc_string(0);
	value args[4];
	args[0] = (value)r;
	args[1] = Val_int(http_code);
	args[2] = caml_copy_int64((uint64_t)content_length);
	args[3] = ml_string;
	caml_callbackN(*ml_url_response,4,args);


	if (ml_url_data == NULL) ml_url_data = caml_named_value("url_data");
	caml_callback2(*ml_url_data,(value)r,ml_string);

	static value *ml_url_complete = NULL;
	if (ml_url_complete == NULL) ml_url_complete = caml_named_value("url_complete");
	caml_callback(*ml_url_complete,(value)r);

	static value *ml_url_failed = NULL;
	if (ml_url_failed == NULL) ml_url_failed = caml_named_value("url_failed");
	value mlerror = caml_copy_string(emsg);
	caml_callback3(*ml_url_failed,(value)r,Val_int(msg->data.result),mlerror);

	free_request(r);
	curl_easy_cleanup(c);

	CAMLreturn0;*/
}
