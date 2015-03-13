#include "plugin_common.h"

static jclass cls = NULL;
#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightOdnoklassniki);

value ok_init (value vappid, value vappsecret, value vappkey) {
	CAMLparam3 (vappid, vappsecret, vappkey);

	GET_ENV;
	GET_CLS;

	char* cappid     = String_val (vappid); 
	char* cappsecret = String_val (vappsecret); 
	char* cappkey    = String_val (vappkey); 

	jstring jappid = (*env)->NewStringUTF(env, cappid);
	jstring jappsecret = (*env)->NewStringUTF(env, cappsecret);
	jstring jappkey = (*env)->NewStringUTF(env, cappkey);

	STATIC_MID(cls, init, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, jappid, jappsecret, jappkey);
	CAMLreturn(Val_unit);
}

value ok_authorize (value vfail, value vsuccess) {
	CAMLparam2 (vfail,vsuccess);

	value *success, *fail;

	GET_ENV;
	GET_CLS;

	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	STATIC_MID(cls, authorize, "(II)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail);
	CAMLreturn(Val_unit);
}
