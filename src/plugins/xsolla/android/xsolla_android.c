#include "lightning_android.h"
#include "engine_android.h"
#include "plugin_common.h"

static jclass cls = NULL;
#define GET_CLS cls = engine_find_class("ru/redspell/lightning/plugins/LightXsolla");

value ml_xsolla_purchase(value sandbox, value vsuccess, value vfail, value vurl, value vtoken) {
	CAMLparam5(vsuccess, vfail, vtoken, vurl, sandbox);
	PRINT_DEBUG("ml_xsolla_purchase");

	value *success, *fail;

	REG_CALLBACK(vsuccess, success);
	REG_CALLBACK(vfail, fail);

	GET_ENV;
	GET_CLS;

	jstring jtoken = (*env)->NewStringUTF(env, String_val(vtoken));
	jstring jurl = (*env)->NewStringUTF(env, String_val(vurl));
	STATIC_MID(cls, purchase, "(IILjava/lang/String;Ljava/lang/String;Z)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail, jtoken, jurl, sandbox == Val_true ? JNI_TRUE: JNI_FALSE);
	(*env)->DeleteLocalRef(env, jtoken);
	(*env)->DeleteLocalRef(env, jurl);

	CAMLreturn(Val_unit);
}

void xsolla_success(void *d) {
	value **data = (value**)d;
	PRINT_DEBUG("xsolla_success");
	RUN_CALLBACK(data[0], Val_unit);
	PRINT_DEBUG("1");
	FREE_CALLBACK(data[0]);
	PRINT_DEBUG("2");
	FREE_CALLBACK(data[1]);
	PRINT_DEBUG("3");
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightXsollaDialog_00024Success_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	value **data = (value**)malloc(sizeof(value*));
	data[0] = (value*)jsuccess;
	data[1] = (value*)jfail;
	RUN_ON_ML_THREAD(&xsolla_success, (void*)data);
}

typedef struct {
	value *fail;
	value *success;
	char *reason;
} xsolla_fail_t;

void xsolla_fail(void *data) {
	xsolla_fail_t *fail = (xsolla_fail_t*)data;
	PRINT_DEBUG("xsolla_fail");
	RUN_CALLBACK(fail->fail, caml_copy_string(fail->reason));
	FREE_CALLBACK(fail->fail);
	FREE_CALLBACK(fail->success);
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightXsollaDialog_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jfail, jstring jreason, jint jsuccess) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	PRINT_DEBUG("creason '%s'", creason);
	xsolla_fail_t *fail = (xsolla_fail_t*)malloc(sizeof(xsolla_fail_t));

	fail->fail = (value*)jfail;
	fail->success = (value*)jsuccess;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&xsolla_fail, fail);
}


