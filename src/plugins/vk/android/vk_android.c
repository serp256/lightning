#include "plugin_common.h"
#include <caml/callback.h>

static jclass cls = NULL;
static int authorized = 0;

#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightVk);

value ml_vk_authorize(value vappid, value vpermissions, value vfail, value vsuccess) {
	if (authorized) return Val_unit;
	authorized = 1;

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
	CAMLlocal2(success, fail);

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, friends, "(II)V");
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);	

	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail);

	CAMLreturn(Val_unit);
}

void vkandroid_free_callbacks(void *data) {
	value *callbacks = (value*)data;
	FREE_CALLBACK(callbacks[0]);
	FREE_CALLBACK(callbacks[1]);
	free(callbacks);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Callback_freeCallbacks(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	value *callbacks = (value*)malloc(sizeof(value) * 2);
	callbacks[0] = (value)jsuccess;
	callbacks[1] = (value)jfail;
	RUN_ON_ML_THREAD(&vkandroid_free_callbacks, (void*)callbacks);
}

void vkandroid_auth_success(void *data) {
	value callbck = (value)data;
	caml_callback(callbck, Val_unit);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024AuthSuccess_nativeRun(JNIEnv *env, jobject this, jint jcb) {
	RUN_ON_ML_THREAD(&vkandroid_auth_success, (void*)jcb);
}

typedef struct {
	value callbck;
	char *reason;
} vkandroid_fail_t;

void vkandroid_fail(void *data) {
	vkandroid_fail_t *fail = (vkandroid_fail_t*)data;
	caml_callback(fail->callbck, caml_copy_string(fail->reason));
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jcb, jstring jreason) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	vkandroid_fail_t *fail = (vkandroid_fail_t*)malloc(sizeof(vkandroid_fail_t));

	fail->callbck = (value)jcb;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&vkandroid_fail, fail);
}

typedef struct {
	value callbck;
	jobjectArray ids;
	jobjectArray names;
	jintArray genders;
} vkandroid_friends_success_t;

void vkandroid_friends_success(void *data) {
	vkandroid_friends_success_t *friends_success = (vkandroid_friends_success_t*)data;

	static value* create_friend = NULL;
	if (!create_friend) create_friend = caml_named_value("create_friend");

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
		const char* cid = (*ML_ENV)->GetStringUTFChars(ML_ENV, jid, JNI_FALSE);
		const char* cname = (*ML_ENV)->GetStringUTFChars(ML_ENV, jname, JNI_FALSE);

		head = caml_alloc_tuple(2);
		Store_field(head, 0, caml_callback3(*create_friend, caml_copy_string(cid), caml_copy_string(cname), Val_int(cgenders[i])));
		Store_field(head, 1, retval);

		retval = head;

		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jid, cid);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jname, cname);
	}

	PRINT_DEBUG("2");

	(*ML_ENV)->ReleaseIntArrayElements(ML_ENV, friends_success->genders, cgenders, 0);
	RUN_CALLBACK(friends_success->callbck, retval);

	PRINT_DEBUG("3");

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->ids);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->names);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->genders);
	free(friends_success);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun(JNIEnv *env, jobject this, jint jcb, jobjectArray jids, jobjectArray jnames, jintArray jgenders) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun");

	vkandroid_friends_success_t *friends_success = (vkandroid_friends_success_t*)malloc(sizeof(vkandroid_friends_success_t));
	friends_success->callbck = (value)jcb;
	friends_success->ids = (*env)->NewGlobalRef(env, jids);
	friends_success->names = (*env)->NewGlobalRef(env, jnames);
	friends_success->genders = (*env)->NewGlobalRef(env, jgenders);

	RUN_ON_ML_THREAD(&vkandroid_friends_success, (void*)friends_success);
}
