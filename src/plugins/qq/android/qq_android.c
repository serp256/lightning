#include "plugin_common.h"
#include <caml/callback.h>

static jclass cls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightQq);

value ml_qq_init (value vappid, value vuid, value vtoken, value vexpires) {
	CAMLparam4(vappid, vuid, vtoken, vexpires);

	PRINT_DEBUG ("ml_qq_init");

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, init, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");

	JString_val(jappid, vappid);
	JString_optval(juid, vuid);
	JString_optval(jtoken, vtoken);
	JString_optval(jexpires, vexpires);

	(*env)->CallStaticVoidMethod(env, cls, mid, jappid, juid, jtoken, jexpires);
	(*env)->DeleteLocalRef(env, jappid);
	(*env)->DeleteLocalRef(env, juid);
	(*env)->DeleteLocalRef(env, jtoken);
	(*env)->DeleteLocalRef(env, jexpires);

	CAMLreturn(Val_unit);
}

value ml_qq_authorize(value vfail, value vsuccess, value vforce) {
	CAMLparam3(vfail, vsuccess, vforce);

	PRINT_DEBUG ("ml_qq_authorize");
	value *success, *fail;

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, authorize, "(IIZ)V");

	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);


	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail, vforce == Val_true ? JNI_TRUE : JNI_FALSE);

	CAMLreturn(Val_unit);
}

value ml_qq_token(value unit) {
	CAMLparam0();
	CAMLlocal1(vtoken);

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, token, "()Ljava/lang/String;");
	jstring jtoken = (*env)->CallStaticObjectMethod(env, cls, mid);
	const char* ctoken = (*env)->GetStringUTFChars(env, jtoken, JNI_FALSE);
	vtoken = caml_copy_string(ctoken);
	(*env)->ReleaseStringUTFChars(env, jtoken, ctoken);

	CAMLreturn(vtoken);
}

value ml_qq_uid(value unit) {
	CAMLparam0();
	CAMLlocal1(vuid);

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, uid, "()Ljava/lang/String;");
	jstring juid = (*env)->CallStaticObjectMethod(env, cls, mid);
	const char* cuid = (*env)->GetStringUTFChars(env, juid, JNI_FALSE);
	vuid = caml_copy_string(cuid);
	(*env)->ReleaseStringUTFChars(env, juid, cuid);

	CAMLreturn(vuid);
}

value ml_qq_logout (value unit) {
	CAMLparam0();
  GET_ENV;
  GET_CLS;

  STATIC_MID(cls, logout, "()V");
	(*env)->CallStaticVoidMethod(env, cls, mid);
	CAMLreturn(Val_unit);
}

value ml_qq_invite (value unit) {
	CAMLparam0();
  GET_ENV;
  GET_CLS;

  STATIC_MID(cls, invite, "()V");
	PRINT_DEBUG("try invite");
	(*env)->CallStaticVoidMethod(env, cls, mid);
	PRINT_DEBUG("after invite");
	CAMLreturn(Val_unit);
}

value ml_qq_share (value title, value summary, value url, value imageUrl) {
	CAMLparam4(title, summary, url, imageUrl);

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, share, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");

	JString_val(jtitle, title);
	JString_val(jsummary, summary);
	JString_val(jurl, url);
	JString_val(jimageUrl, imageUrl);

	(*env)->CallStaticVoidMethod(env, cls, mid, jtitle, jsummary, jurl, jimageUrl);
	(*env)->DeleteLocalRef(env, jtitle);
	(*env)->DeleteLocalRef(env, jsummary);
	(*env)->DeleteLocalRef(env, jurl);
	(*env)->DeleteLocalRef(env, jimageUrl);

}
void qqandroid_auth_success(void *d) {
	PRINT_DEBUG("qqandroid_auth_success");
	value **data = (value**)d;
	RUN_CALLBACK(data[0], Val_unit);
	FREE_CALLBACK(data[0]);
	FREE_CALLBACK(data[1]);
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightQq_00024AuthSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightQQ_00024AuthSuccess_nativeRun");
	value **data = (value**)malloc(sizeof(value*));
	data[0] = (value*)jsuccess;
	data[1] = (value*)jfail;
	RUN_ON_ML_THREAD(&qqandroid_auth_success, (void*)data);
}

typedef struct {
	value *fail;
	value *success;
	char *reason;
} qqandroid_fail_t;

void qqandroid_fail(void *data) {
	qqandroid_fail_t *fail = (qqandroid_fail_t*)data;
	RUN_CALLBACK(fail->fail, caml_copy_string(fail->reason));
	FREE_CALLBACK(fail->fail);
	FREE_CALLBACK(fail->success);
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightQq_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jfail, jstring jreason, jint jsuccess) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	PRINT_DEBUG("creason '%s'", creason);
	qqandroid_fail_t *fail = (qqandroid_fail_t*)malloc(sizeof(qqandroid_fail_t));

	fail->fail = (value*)jfail;
	fail->success = (value*)jsuccess;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&qqandroid_fail, fail);
}

