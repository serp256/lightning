#include "light_common.h"
#include "android/mlwrapper_android.h"


void ml_fb_init(value app_id) {
	PRINT_DEBUG("+++++++++++++++++++++++++++++++++++++++++");
	PRINT_DEBUG("ml_fb_init");
  JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass fbCls = (*env)->FindClass(env, "ru/redspell/lightning/AndroidFB");
	jmethodID init = (*env)->GetStaticMethodID(env, fbCls, "init", "(Ljava/lang/String;)V");
	jstring japp_id = (*env)->NewStringUTF(env, String_val(app_id));
  (*env)->CallStaticVoidMethod(env, fbCls, init, japp_id);
  (*env)->DeleteLocalRef(env, fbCls);
	(*env)->DeleteLocalRef(env, japp_id);
	PRINT_DEBUG("ml_fb_init FINISHED");
}


static value fb_auth_success = 0;
static value fb_auth_error = 0;

void ml_fb_authorize(value olen, value permissions, value cb, value ecb) {
	CAMLparam4(olen,permissions,cb,ecb);
	fb_auth_success = cb;
	caml_register_generational_global_root(&fb_auth_success);
	fb_auth_error = ecb;
	caml_register_generational_global_root(&fb_auth_error);
	int len = Int_val (olen);
	PRINT_DEBUG("ml_fb_authorize");
  JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("JNI GET");
	jclass fbCls = (*env)->FindClass(env, "ru/redspell/lightning/AndroidFB");
	PRINT_DEBUG("CLASS FOUND ");
	jmethodID auth = (*env)->GetStaticMethodID(env, fbCls, "authorize", "([Ljava/lang/String;)V");
	PRINT_DEBUG("METHOD FOUND");
	
	jobjectArray jpermissions = (*env)->NewObjectArray(env,len,(*env)->FindClass(env,"java/lang/String"),(*env)->NewStringUTF(env,""));

	value perms = permissions;
	value v;
	int i = 0;
	while (perms != NILL) {
		v = Field(perms,0);
		(*env)->SetObjectArrayElement(env,jpermissions,i,(*env)->NewStringUTF(env,String_val(v)));
		i++;
		perms = Field(perms,1);
	}

  (*env)->CallStaticVoidMethod(env, fbCls, auth, jpermissions);
	PRINT_DEBUG("CALL METHOD");
  (*env)->DeleteLocalRef(env, fbCls);
  (*env)->DeleteLocalRef(env, jpermissions);
	PRINT_DEBUG("DELETE REF");

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_successAuthorize(JNIEnv *env, jobject this) {
	PRINT_DEBUG("AUTH SUCCESS CALLBACK");
	if (fb_auth_success) {
		caml_callback(fb_auth_success, Val_unit);
		caml_remove_generational_global_root(&fb_auth_success);
		fb_auth_success = 0;
	};
	if (fb_auth_error) {
		caml_remove_generational_global_root(&fb_auth_error);
		fb_auth_error = 0;
	};
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_errorAuthorize(JNIEnv *env, jobject this) {
	PRINT_DEBUG("AUTH ERROR CALLBACK");
	if (fb_auth_success) {
		caml_remove_generational_global_root(&fb_auth_success);
		fb_auth_success = 0;
	};
	if (fb_auth_error) {
		caml_callback(fb_auth_error, Val_unit);
		caml_remove_generational_global_root(&fb_auth_error);
		fb_auth_error = 0;
	};
}

static value fb_graph_callback = 0;
static value fb_graph_error = 0;

void ml_fb_graph_api(value cb, value ecb, value path, value oparams_len, value params) {
	CAMLparam5(path,oparams_len,params, cb, ecb);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jclass fbCls = (*env)->FindClass(env, "ru/redspell/lightning/AndroidFB");
	PRINT_DEBUG("CLASS FOUND ");
	jmethodID graph_api = (*env)->GetStaticMethodID(env, fbCls, "graphAPI", "(Ljava/lang/String;[[Ljava/lang/String;)V");
	PRINT_DEBUG("METHOD FOUND");
	if (cb != NONE) {
		fb_graph_callback = Field(cb,0);
		caml_register_generational_global_root(&fb_graph_callback);
	};
	if (ecb != NONE) {
		fb_graph_error = Field(ecb,0);
		caml_register_generational_global_root(&fb_graph_error);
	};

	int len = Int_val(oparams_len);
	jobjectArray jparams = (*env)->NewObjectArray(env,len,(*env)->FindClass(env,"[Ljava/lang/String;"),(*env)->NewObjectArray(env,2,(*env)->FindClass(env, "java/lang/String"),(*env)->NewStringUTF(env,"pizda")));

	value prms = params;
	value v;
	int i = 0;
	while (prms != NILL) {
		v = Field(prms,0);
		jobjectArray jrow = (*env)->NewObjectArray(env,2,(*env)->FindClass(env, "java/lang/String"),(*env)->NewStringUTF(env,"pizda"));
		(*env)->SetObjectArrayElement(env,jrow,0,(*env)->NewStringUTF(env,String_val(Field(v,0))));
		(*env)->SetObjectArrayElement(env,jrow,1,(*env)->NewStringUTF(env,String_val(Field(v,1))));
		(*env)->SetObjectArrayElement(env,jparams,i,jrow);
		(*env)->DeleteLocalRef(env, jrow);
		i++;
		prms = Field(prms,1);
	}
	PRINT_DEBUG("GET PARAMS");
	(*env)->CallStaticVoidMethod(env, fbCls, graph_api, (*env)->NewStringUTF(env,String_val(path)),jparams );
	PRINT_DEBUG("FINISH METHOD");
	(*env)->DeleteLocalRef(env, fbCls);
	(*env)->DeleteLocalRef(env, jparams);

	CAMLreturn0;
}

value ml_fb_check_auth_token(value unit) {
	CAMLparam0();
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jclass fbCls = (*env)->FindClass(env, "ru/redspell/lightning/AndroidFB");
	jmethodID check = (*env)->GetStaticMethodID(env, fbCls, "check_auth_token", "()Z");
	value check_result = (Val_bool((*env)->CallStaticBooleanMethod(env, fbCls, check)));
	(*env)->DeleteLocalRef(env, fbCls);
	CAMLreturn(check_result);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_successGraphAPI(JNIEnv *env, jobject this, jstring response) {
	PRINT_DEBUG("SUCCESS CALLBACK");
	const char *l = (*env)->GetStringUTFChars(env, response, JNI_FALSE);
	jsize slen = (*env)->GetStringUTFLength(env,response);
	PRINT_DEBUG("SLEN %d", slen);
	value mresponse = caml_alloc_string(slen);
	memcpy(String_val(mresponse),l,slen);

	PRINT_DEBUG("GET STRING: %s",String_val(mresponse));
	if (fb_graph_callback) {
			PRINT_DEBUG("caml_callback start");
		caml_callback(fb_graph_callback, mresponse);
		caml_remove_generational_global_root(&fb_graph_callback);
		fb_graph_callback = 0;
	};
	PRINT_DEBUG("caml_callback finished");
	if (fb_graph_error) {
		caml_remove_generational_global_root(&fb_graph_error);
		fb_graph_error = 0;
	};
	(*env)->ReleaseStringUTFChars(env, response, l);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_errorGraphAPI(JNIEnv *env, jobject this, jstring error) {
	PRINT_DEBUG("ERROR CALLBACK");
	const char *l = (*env)->GetStringUTFChars(env, error, JNI_FALSE);
	value merror = caml_copy_string(l);

	PRINT_DEBUG("GET STRING: %s",String_val(merror));
	if (fb_graph_callback) {
		caml_remove_generational_global_root(&fb_graph_callback);
		fb_graph_callback = 0;
	};
	if (fb_graph_error) {
		caml_callback(fb_graph_error, merror);
		caml_remove_generational_global_root(&fb_graph_error);
		fb_graph_error = 0;
	};
	PRINT_DEBUG("caml_callback finished");
	(*env)->ReleaseStringUTFChars(env, error, l);
}
