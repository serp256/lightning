#include "plugin_common.h"

static jclass whatsappCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(whatsappCls,ru/redspell/lightning/plugins/LightWhatsapp);

value ml_whatsapp_text(value v_text) {
	GET_ENV;
	GET_CLS;

	JString_val(j_text, v_text);
	
	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, whatsappCls, "text", "(Ljava/lang/String;)Z");

	jboolean retval = (*env)->CallStaticBooleanMethod(env, whatsappCls, mid, j_text);
	(*env)->DeleteLocalRef(env, j_text);

	return (retval ? Val_true : Val_false);
}

value ml_whatsapp_picture(value v_pic) {
	GET_ENV;
	GET_CLS;

	JString_val(j_pic, v_pic);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, whatsappCls, "picture", "(Ljava/lang/String;)Z");

	jboolean retval = (*env)->CallStaticBooleanMethod(env, whatsappCls, mid, j_pic);
	(*env)->DeleteLocalRef(env, j_pic);

	return (retval ? Val_true : Val_false);
}