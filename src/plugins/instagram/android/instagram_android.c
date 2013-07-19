#include "plugin_common.h"

static jclass instagramCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(instagramCls,ru/redspell/lightning/plugins/LightInstagram);

value ml_instagram_post(value v_fname, value v_text) {
	CAMLparam2(v_fname, v_text);

	GET_ENV;
	GET_CLS;

	JString_val(j_fname, v_fname);
	JString_val(j_text, v_text);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, instagramCls, "post", "(Ljava/lang/String;Ljava/lang/String;)Z");

	jboolean retval = (*env)->CallStaticBooleanMethod(env, instagramCls, mid, j_text, j_fname);
	(*env)->DeleteLocalRef(env, j_text);
	(*env)->DeleteLocalRef(env, j_fname);

	CAMLreturn(retval ? Val_true : Val_false);
} 