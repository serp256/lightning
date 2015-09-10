#include "plugin_common.h"
#include <caml/callback.h>

static jclass cls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightVk);

value ml_vk_init(value unit) {
	CAMLparam0();
	PRINT_DEBUG("ml_vk_init");
	GET_ENV;
	GET_CLS;


	STATIC_MID(cls, init, "()V");
	(*env)->CallStaticVoidMethod(env, cls, mid);
	CAMLreturn(Val_unit);
}

value ml_vk_authorize(value vappid, value vpermissions, value vfail, value vsuccess, value vforce) {
	CAMLparam4(vappid, vpermissions, vfail, vsuccess);
	CAMLlocal1(head);

	PRINT_DEBUG ("ml_vk_authorize");
	value *success, *fail;

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, authorize, "(Ljava/lang/String;[Ljava/lang/String;IIZ)V");

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

	PRINT_DEBUG("vforce == Val_true %d", vforce == Val_true);

	(*env)->CallStaticVoidMethod(env, cls, mid, jappid, jperms, (jint)success, (jint)fail, vforce == Val_true ? JNI_TRUE : JNI_FALSE);
	(*env)->DeleteLocalRef(env, jperms);
	(*env)->DeleteLocalRef(env, jappid);

	CAMLreturn(Val_unit);
}

value ml_vk_authorize_byte(value *argv, int n) {
	PRINT_DEBUG ("ml_vk_authorize_byte");
	return ml_vk_authorize(argv[0], argv[1], argv[2], argv[3], argv[4]);
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

value ml_vk_logout (value unit) {
	CAMLparam0();
  GET_ENV;
  GET_CLS;

  STATIC_MID(cls, logout, "()V");
	(*env)->CallStaticObjectMethod(env, cls, mid);
	CAMLreturn(Val_unit);
}


value ml_vk_apprequest(value vfail, value vsuccess, value vuid) {
	CAMLparam3(vfail, vsuccess, vuid);

	value *success, *fail;

	GET_ENV;
	GET_CLS;
	STATIC_MID(cls, apprequest, "(IILjava/lang/String;)V");
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);


	jstring juid;
	VAL_TO_JSTRING(vuid, juid);
	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail, juid);
	(*env)->DeleteLocalRef(env, juid);

	CAMLreturn(Val_unit);
}

void vkandroid_auth_success(void *d) {
	value **data = (value**)d;
	PRINT_DEBUG("vkandroid_auth_success");
	RUN_CALLBACK(data[0], Val_unit);
	PRINT_DEBUG("1");
	FREE_CALLBACK(data[0]);
	PRINT_DEBUG("2");
	FREE_CALLBACK(data[1]);
	PRINT_DEBUG("3");
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024AuthSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	value **data = (value**)malloc(sizeof(value*));
	data[0] = (value*)jsuccess;
	data[1] = (value*)jfail;
	RUN_ON_ML_THREAD(&vkandroid_auth_success, (void*)data);
}

typedef struct {
	value *fail;
	value *success;
	char *reason;
} vkandroid_fail_t;

void vkandroid_fail(void *data) {
	vkandroid_fail_t *fail = (vkandroid_fail_t*)data;
	RUN_CALLBACK(fail->fail, caml_copy_string(fail->reason));
	FREE_CALLBACK(fail->fail);
	FREE_CALLBACK(fail->success);
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jfail, jstring jreason, jint jsuccess) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	PRINT_DEBUG("creason '%s'", creason);
	vkandroid_fail_t *fail = (vkandroid_fail_t*)malloc(sizeof(vkandroid_fail_t));

	fail->fail = (value*)jfail;
	fail->success = (value*)jsuccess;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&vkandroid_fail, fail);
}

typedef struct {
	value *success;
	value *fail;
	jobjectArray friends;
} vkandroid_friends_success_t;

void vkandroid_friends_success(void *data) {
	CAMLparam0();
	CAMLlocal2(retval, head);
	PRINT_DEBUG ("vkandroid_friends_success");
	vkandroid_friends_success_t *friends_success = (vkandroid_friends_success_t*)data;

	static value* create_friend = NULL;
	PRINT_DEBUG ("1");
	if (!create_friend) create_friend = caml_named_value("create_user");
	PRINT_DEBUG ("2");

	retval = Val_int(0);

	int cnt = (*ML_ENV)->GetArrayLength(ML_ENV, friends_success->friends);
	int i;

	static jfieldID id_fid = 0;
	static jfieldID name_fid = 0;
	static jfieldID photo_fid = 0;
	static jfieldID gender_fid = 0;
	static jfieldID online_fid = 0;
	static jfieldID lastseen_fid = 0;

	if (!id_fid) {
		jclass cls = engine_find_class("ru/redspell/lightning/plugins/LightVk$Friend");

		id_fid = (*ML_ENV)->GetFieldID(ML_ENV, cls, "id", "Ljava/lang/String;");
		name_fid = (*ML_ENV)->GetFieldID(ML_ENV, cls, "name", "Ljava/lang/String;");
		photo_fid = (*ML_ENV)->GetFieldID(ML_ENV, cls, "photo", "Ljava/lang/String;");
		gender_fid = (*ML_ENV)->GetFieldID(ML_ENV, cls, "gender", "I");
		online_fid = (*ML_ENV)->GetFieldID(ML_ENV, cls, "online", "Z");
		lastseen_fid = (*ML_ENV)->GetFieldID(ML_ENV, cls, "lastSeen", "I");
	}

	for (i = 0; i < cnt; i++) {
		jobject jfriend = (*ML_ENV)->GetObjectArrayElement(ML_ENV, friends_success->friends, i);

		jstring jid = (jstring)(*ML_ENV)->GetObjectField(ML_ENV, jfriend, id_fid);
		jstring jname = (jstring)(*ML_ENV)->GetObjectField(ML_ENV, jfriend, name_fid);
		jstring jphoto = (jstring)(*ML_ENV)->GetObjectField(ML_ENV, jfriend, photo_fid);
		jint jgender = (*ML_ENV)->GetIntField(ML_ENV, jfriend, gender_fid);
		jboolean jonline = (*ML_ENV)->GetBooleanField(ML_ENV, jfriend, online_fid);
		jint jlast_seen = (*ML_ENV)->GetIntField(ML_ENV, jfriend, lastseen_fid);
		const char* cid = (*ML_ENV)->GetStringUTFChars(ML_ENV, jid, JNI_FALSE);
		const char* cname = (*ML_ENV)->GetStringUTFChars(ML_ENV, jname, JNI_FALSE);
		const char* cphoto = (*ML_ENV)->GetStringUTFChars(ML_ENV, jphoto, JNI_FALSE);

		head = caml_alloc_tuple(2);
		value args[6] = { caml_copy_string(cid), caml_copy_string(cname), Val_int(jgender), caml_copy_string(cphoto), jonline == JNI_TRUE ? Val_true : Val_false, caml_copy_double((double)jlast_seen) };
		Store_field(head, 0, caml_callbackN(*create_friend, 6, args));
		Store_field(head, 1, retval);

		retval = head;

		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jid, cid);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jname, cname);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jphoto, cphoto);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jid);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jname);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jphoto);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jfriend);
	}

	PRINT_DEBUG ("run succ");
	RUN_CALLBACK(friends_success->success, retval);
	FREE_CALLBACK(friends_success->success);
	FREE_CALLBACK(friends_success->fail);
	PRINT_DEBUG ("freed");

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->friends);
	PRINT_DEBUG ("del fr");
	free(friends_success);
	PRINT_DEBUG ("free struct");

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jobjectArray jfriends) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightVk_00024FriendsSuccess_nativeRun");

	vkandroid_friends_success_t *friends_success = (vkandroid_friends_success_t*)malloc(sizeof(vkandroid_friends_success_t));
	friends_success->success = (value*)jsuccess;
	friends_success->fail = (value*)jfail;
	friends_success->friends = (*env)->NewGlobalRef(env, jfriends);

	RUN_ON_ML_THREAD(&vkandroid_friends_success, (void*)friends_success);
}
