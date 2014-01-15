#include "mlwrapper_android.h"

value ml_vibration(value timeVal) {
	int time = Int_val(timeVal);
//	caml_failwith("FLAG 1");
	JNIEnv *env = NULL;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	if (env == NULL){
		caml_failwith("env is NULL");
	}

//	caml_failwith("FLAG 3");
	jmethodID vibroMethod = (*env)->GetMethodID(env, jViewCls, "vibrate", "(I)V");
//	caml_failwith("FLAG 4");
	if (vibroMethod == NULL) {
		caml_failwith("can't find 'vibrate' method");
	}
	else
		(*env)->CallVoidMethod(env, jView, vibroMethod, time);
	(*env)->DeleteLocalRef(env, vibroMethod);
	return Val_unit;
}
