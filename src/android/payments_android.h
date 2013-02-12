#include "mlwrapper_android.h"

#define GET_FID(name) name##Fid = (*env)->GetFieldID(env, cls, #name, "Ljava/lang/String;");

#define JNI_TO_VAL(name) jstring j_##name = (*env)->GetObjectField(env, this, name##Fid);	\
	const char* c_##name = (*env)->GetStringUTFChars(env, j_##name, JNI_FALSE);				\
	value v_##name = caml_copy_string(c_##name);											\
	(*env)->ReleaseStringUTFChars(env, j_##name, c_##name);
