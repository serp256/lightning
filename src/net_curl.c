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

// we need add select here ????? 

static CURLM *curlm = NULL;

int net_running = 0;

struct request {
	CURL *handle;
	char *url;
	struct curl_slist *headers;
	char *data;
	int headers_done;
};

size_t writefunction(char *buffer,size_t size,size_t nitems, void *p) {
	CAMLparam0();
	CAMLlocal1(ml_string);
	struct request *r = (struct request*)p;
	if (!r->headers_done) {
		static value *ml_url_response = NULL;
		if (ml_url_response == NULL) ml_url_response = caml_named_value("url_response");
		long http_code;
		curl_easy_getinfo(r->handle,CURLINFO_RESPONSE_CODE,&http_code);
		char *content_type;
		curl_easy_getinfo(r->handle,CURLINFO_CONTENT_TYPE,&content_type);
		PRINT_DEBUG("content-type: %s",content_type);
		double content_length;
		curl_easy_getinfo(r->handle,CURLINFO_CONTENT_LENGTH_DOWNLOAD,&content_length);
		PRINT_DEBUG("content-length: %llu",(uint64_t)content_length);
		r->headers_done = 1;
		if (content_type != NULL) ml_string = caml_copy_string(content_type);
		else ml_string = caml_alloc_string(0);
		value args[4];
		args[0] = (value)r;
		args[1] = Val_int(http_code);
		args[2] = caml_copy_int64((uint64_t)content_length);
		args[3] = ml_string;
		caml_callbackN(*ml_url_response,4,args);
	};
	size_t s = size * nitems;
	ml_string = caml_alloc_string(s);
	if (s > 0) memcpy(String_val(ml_string),buffer,s);
	static value *ml_url_data = NULL;
	if (ml_url_data == NULL) ml_url_data = caml_named_value("url_data");
	caml_callback2(*ml_url_data,(value)r,ml_string);
	PRINT_DEBUG("writefunction called");
	CAMLreturnT(size_t,s);
}

void net_perform() {
	PRINT_DEBUG("net perform");
	int running_handles;
	int r = curl_multi_perform(curlm,&running_handles);
	if (r != CURLM_OK && r != CURLM_CALL_MULTI_PERFORM) {
		const char *err = curl_multi_strerror(r);
		ERROR("curl error: %s",err);
		exit(3); // ?????
	}
	if (running_handles < net_running) { // we need check info
		net_running = running_handles;
		CURLMsg *msg; /* for picking up messages with the transfer status */
		int msgs_left; /* how many messages are left */
		CURL *c;
		while ((msg = curl_multi_info_read(curlm, &msgs_left))) {
			if (msg->msg == CURLMSG_DONE) {
				c = msg->easy_handle;
				struct request *r = NULL;
				curl_easy_getinfo(c,CURLINFO_PRIVATE,&r);
				PRINT_DEBUG("url_loader complete: %lu",(long)r);
				// вызвать окамл и все похерить нахуй
				if (msg->data.result == CURLE_OK) {
					static value *ml_url_complete = NULL;
					if (ml_url_complete == NULL) ml_url_complete = caml_named_value("url_complete");
					caml_callback(*ml_url_complete,(value)r);
				} else {
					const char* emsg = curl_easy_strerror(msg->data.result);
					static value *ml_url_failed = NULL;
					if (ml_url_failed == NULL) ml_url_failed = caml_named_value("url_failed");
					value mlerror = caml_copy_string(emsg);
					caml_callback3(*ml_url_failed,(value)r,Val_int(msg->data.result),mlerror);
				};
				free(r->url);
				if (r->headers != NULL) curl_slist_free_all(r->headers); 
				if (r->data != NULL) free(r->data);
				free(r);
				curl_multi_remove_handle(curlm,c);
				curl_easy_cleanup(c);
			}
		};
	}
}

CAMLprim value ml_URLConnection(value url, value method, value headers, value data) {
	if (curlm == NULL) {
		curl_global_init(CURL_GLOBAL_NOTHING);
		curlm = curl_multi_init();
	};
	struct request *r = (struct request*)caml_stat_alloc(sizeof(struct request));
	r->handle = curl_easy_init();
	r->url = strdup(String_val(url));
	curl_easy_setopt(r->handle,CURLOPT_URL,r->url);
	if (Int_val(method) == caml_hash_variant("POST")) curl_easy_setopt(r->handle,CURLOPT_POST,1);
	r->headers = NULL;
	if (Is_block(headers)) {
		value h = headers;
		do {
			r->headers = curl_slist_append(r->headers,strdup(String_val(Field(h,0))));
			h = Field(h,1);
		} while (Is_block(h));
		curl_easy_setopt(r->handle,CURLOPT_HTTPHEADER,r->headers);
	}
	r->headers_done = 0;
	if (Is_block(data)) {
		value d = Field(data,0);
		size_t l = caml_string_length(d);
		r->data = (char*)malloc(l);
		memcpy(r->data,String_val(d),l);
		curl_easy_setopt(r->handle,CURLOPT_POSTFIELDS,r->data);
		curl_easy_setopt(r->handle,CURLOPT_POSTFIELDSIZE,l);
	} else r->data = NULL;
	curl_easy_setopt(r->handle,CURLOPT_WRITEFUNCTION,&writefunction);
	curl_easy_setopt(r->handle,CURLOPT_WRITEDATA,(void*)r);
	curl_easy_setopt(r->handle,CURLOPT_PRIVATE,(void*)r);
	curl_multi_add_handle(curlm,r->handle);
	net_running++;
	return (value)r;
}

void ml_URLConnection_cancel(value r) {
}


void net_run () {
	if (net_running > 0) net_perform ();
}
