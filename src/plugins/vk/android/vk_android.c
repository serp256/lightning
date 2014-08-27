#include "plugin_common.h"
#include <caml/callback.h>

static jclass cls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightVk);

value ml_vk_authorize(value vappid, value vpermissions, value vfail, value vsuccess) {
	CAMLparam4(vappid, vpermissions, vfail, vsuccess);
	CAMLlocal1(head);

	value *success, *fail;

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

	jobjectArray jperms = (*env)->NewObjectArray(env, perms_len, engine_find_class("java/lang/String"), NULL);
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

	value *success, *fail;

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, friends, "(II)V");
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail);

	CAMLreturn(Val_unit);
}

value ml_vk_users(value vfail, value vsuccess, value vids) {
	CAMLparam3(vfail, vsuccess, vids);

	value *success, *fail;

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, users, "(Ljava/lang/String;II)V");
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	jstring jids;
	VAL_TO_JSTRING(vids, jids);
	(*env)->CallStaticVoidMethod(env, cls, mid, jids, (jint)success, (jint)fail);
	(*env)->DeleteLocalRef(env, jids);

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

void vkandroid_free_callbacks(void *data) {
        value **callbacks = (value**)data;
        FREE_CALLBACK(callbacks[0]);
        FREE_CALLBACK(callbacks[1]);
        free(callbacks);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Callback_freeCallbacks(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	value **callbacks = (value**)malloc(sizeof(value*) * 2);
	callbacks[0] = (value*)jsuccess;
	callbacks[1] = (value*)jfail;
	RUN_ON_ML_THREAD(&vkandroid_free_callbacks, (void*)callbacks);
}

void vkandroid_auth_success(void *data) {
	value *callbck = (value*)data;
	RUN_CALLBACK(callbck, Val_unit);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024AuthSuccess_nativeRun(JNIEnv *env, jobject this, jint jcb) {
	RUN_ON_ML_THREAD(&vkandroid_auth_success, (void*)jcb);
}

typedef struct {
	value *callbck;
	char *reason;
} vkandroid_fail_t;

void vkandroid_fail(void *data) {
	vkandroid_fail_t *fail = (vkandroid_fail_t*)data;
	RUN_CALLBACK(fail->callbck, caml_copy_string(fail->reason));
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jcb, jstring jreason) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	vkandroid_fail_t *fail = (vkandroid_fail_t*)malloc(sizeof(vkandroid_fail_t));

	fail->callbck = (value*)jcb;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&vkandroid_fail, fail);
}

typedef struct {
	value *callbck;
	jobjectArray ids;
	jobjectArray names;
	jintArray genders;
	jobjectArray photos;
} vkandroid_friends_success_t;

void vkandroid_friends_success(void *data) {
	vkandroid_friends_success_t *friends_success = (vkandroid_friends_success_t*)data;

	static value* create_friend = NULL;
	if (!create_friend) create_friend = caml_named_value("create_user");

	CAMLparam0();
	CAMLlocal2(retval, head);
	retval = Val_int(0);

	PRINT_DEBUG("1");

	int cnt = (*ML_ENV)->GetArrayLength(ML_ENV, friends_success->genders);
	int i;
	jint* cgenders = (*ML_ENV)->GetIntArrayElements(ML_ENV, friends_success->genders, JNI_FALSE);

	for (i = 0; i < cnt; i++) {
		jstring jid = (jstring)(*ML_ENV)->GetObjectArrayElement(ML_ENV, friends_success->ids, i);
		jstring jname = (jstring)(*ML_ENV)->GetObjectArrayElement(ML_ENV, friends_success->names, i);
		jstring jphoto = (jstring)(*ML_ENV)->GetObjectArrayElement(ML_ENV, friends_success->photos, i);
		const char* cid = (*ML_ENV)->GetStringUTFChars(ML_ENV, jid, JNI_FALSE);
		const char* cname = (*ML_ENV)->GetStringUTFChars(ML_ENV, jname, JNI_FALSE);
		const char* cphoto = (*ML_ENV)->GetStringUTFChars(ML_ENV, jphoto, JNI_FALSE);

		head = caml_alloc_tuple(2);
		value args[4] = { caml_copy_string(cid), caml_copy_string(cname), Val_int(cgenders[i]), caml_copy_string(cphoto) };
		Store_field(head, 0, caml_callbackN(*create_friend, 4, args));
		Store_field(head, 1, retval);

		retval = head;

		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jid, cid);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jname, cname);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jphoto, cphoto);
	}

	PRINT_DEBUG("2");

	(*ML_ENV)->ReleaseIntArrayElements(ML_ENV, friends_success->genders, cgenders, 0);
	RUN_CALLBACK(friends_success->callbck, retval);

	PRINT_DEBUG("3");

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->ids);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->names);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->genders);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->photos);
	free(friends_success);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun(JNIEnv *env, jobject this, jint jcb, jobjectArray jids, jobjectArray jnames, jintArray jgenders, jobjectArray jphotos) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun");

	vkandroid_friends_success_t *friends_success = (vkandroid_friends_success_t*)malloc(sizeof(vkandroid_friends_success_t));
	friends_success->callbck = (value*)jcb;
	friends_success->ids = (*env)->NewGlobalRef(env, jids);
	friends_success->names = (*env)->NewGlobalRef(env, jnames);
	friends_success->genders = (*env)->NewGlobalRef(env, jgenders);
	friends_success->photos = (*env)->NewGlobalRef(env, jphotos);

	RUN_ON_ML_THREAD(&vkandroid_friends_success, (void*)friends_success);
}
