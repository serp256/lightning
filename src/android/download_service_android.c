#include "lightning_android.h"
#include "engine_android.h"
#include <caml/callback.h>

static jclass servCls = NULL;
#define GET_ENV JNIEnv *env = ML_ENV;
#define STATIC_MID(cls, name, sig) static jmethodID mid = 0; if (!mid) mid = (*env)->GetStaticMethodID(env, cls, #name, sig);
#define GET_CLS if (!servCls) servCls = engine_find_class("ru/redspell/lightning/download_service/LightDownloadService");

value ml_DownloadService(value compress, value url, value path, value errCb, value prgrssCb, value cb) {
	CAMLparam5(url, path, errCb, prgrssCb, cb);
	PRINT_DEBUG("START DOWNLOAD FILE WITH SERVICE");

	GET_ENV;
	GET_CLS;

	STATIC_MID(servCls, download, "(Ljava/lang/String;)V");
	jstring jurl = (*env)->NewStringUTF(env, String_val(url));
	(*env)->CallStaticVoidMethod(env, servCls, mid,jurl);

	CAMLreturn(Val_unit);
}

value ml_DownloadService_byte(value *argv, int n) {
	return ml_DownloadService(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}
