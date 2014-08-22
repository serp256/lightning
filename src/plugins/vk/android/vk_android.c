#include "plugin_common.h"

static jclass cls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightVk);

value ml_vk_authorize(value vappid, value vpermissions, value vfail, value vsuccess) {
	CAMLparam4(vappid, vpermissions, vfail, vsuccess);
	CAMLlocal3(success, fail, head);

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, authorize, "(Ljava/lang/String;[Ljava/lang/String;II)V");

	JString_val(jappid, vappid);
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	int perms_len = 0;
	head = vpermissions;
	while (Is_block(head)) {
		perms_len++;
		head = Field(head, 1);
	}

	jobjectArray jperms = (*env)->NewObjectArray(env, perms_len, (*env)->FindClass(env, "java/lang/String"), NULL);
	jstring jperm;
	int i = 0;

	head = vpermissions;
	while (Is_block(head)) {
		jperm = (*env)->NewStringUTF(env, String_val(Field(head, 0)));
		(*env)->SetObjectArrayElement(env, jperms, i++, jperm);
		(*env)->DeleteLocalRef(env, jperm);
		head = Field(head, 1);
	}

	(*env)->CallStaticVoidMethod(env, cls, mid, jappid, jperms, (jint)success, (jint)fail);
	(*env)->DeleteLocalRef(env, jperms);
	(*env)->DeleteLocalRef(env, jappid);

	CAMLreturn(Val_unit);
}

value ml_vk_friends(value vfail, value vsuccess, value vt) {
	CAMLparam3(vfail, vsuccess, vt);
	CAMLlocal2(success, fail);

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, friends, "(II)V");
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);	

	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail);

	CAMLreturn(Val_unit);
}

value ml_vk_token(value t) {
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

value ml_vk_uid(value t) {
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

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Callback_freeCallbacks(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	value vsuccess = (value)jsuccess;
	value vfail = (value)jfail;
	FREE_CALLBACK(vsuccess);
	FREE_CALLBACK(vfail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024AuthSuccess_nativeRun(JNIEnv *env, jobject this, jint jcb) {
	value vcb = (value)jcb;
	caml_callback(vcb, Val_unit);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jcb, jstring jreason) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	value vcb = (value)jcb;
	value vreason = caml_copy_string(creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	caml_callback(vcb, vreason);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun(JNIEnv *env, jobject this, jint jcb, jobjectArray jids, jobjectArray jnames, jintArray jgenders) {
	static value* create_friend = NULL;
	if (!create_friend) create_friend = caml_named_value("create_friend");

	CAMLparam0();
	CAMLlocal2(retval, head);
	retval = Val_int(0);

	int cnt = (*env)->GetArrayLength(env, jgenders);
	int i;
	jint* cgenders = (*env)->GetIntArrayElements(env, jgenders, JNI_FALSE);

	for (i = 0; i < cnt; i++) {
		jstring jid = (jstring)(*env)->GetObjectArrayElement(env, jids, i);		
		jstring jname = (jstring)(*env)->GetObjectArrayElement(env, jnames, i);
		const char* cid = (*env)->GetStringUTFChars(env, jid, JNI_FALSE);
		const char* cname = (*env)->GetStringUTFChars(env, jname, JNI_FALSE);

		head = caml_alloc_tuple(2);
		Store_field(head, 0, caml_callback3(*create_friend, caml_copy_string(cid), caml_copy_string(cname), Val_int(cgenders[i])));
		Store_field(head, 1, retval);

		retval = head;

		(*env)->ReleaseStringUTFChars(env, jid, cid);
		(*env)->ReleaseStringUTFChars(env, jname, cname);
	}

	(*env)->ReleaseIntArrayElements(env, jgenders, cgenders, 0);

	value vcb = (value)jcb;
	RUN_CALLBACK(vcb, retval);
	CAMLreturn0;
}
