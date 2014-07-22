#include "lightning_android.h"
#include "engine.h"

value ml_showUrl(value vurl) {
	CAMLparam1(vurl);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "showUrl", "(Ljava/lang/String;)V");

	jstring jurl;
	VAL_TO_JSTRING(vurl, jurl);

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jurl);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jurl);

	CAMLreturn(Val_unit);
}

value ml_getUDID() {
	CAMLparam0();
	CAMLlocal1(vudid);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getUDID", "()Ljava/lang/String;");

	jstring judid = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(judid, vudid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, judid);
	
	CAMLreturn(vudid);
}

value ml_getOldUDID() {
	CAMLparam0();
	CAMLlocal1(vudid);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getOldUDID", "()Ljava/lang/String;");
	
	jstring judid = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(judid, vudid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, judid);

	CAMLreturn(vudid);
}

value ml_malinfo(value p) {
	return caml_alloc_tuple(3);
}

value ml_openURL(value vurl) {
	jstring jurl;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "openURL", "(Ljava/lang/String;)V");

	VAL_TO_JSTRING(vurl, jurl);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jurl);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jurl);
	
	return Val_unit;
}
