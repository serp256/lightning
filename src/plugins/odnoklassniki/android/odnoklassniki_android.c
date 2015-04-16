#include "plugin_common.h"
#include <caml/callback.h>

static jclass cls = NULL;
#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightOdnoklassniki);

value ok_init (value vappid, value vappsecret, value vappkey) {
	CAMLparam3 (vappid, vappsecret, vappkey);

	GET_ENV;
	GET_CLS;

	char* cappid     = String_val (vappid); 
	char* cappsecret = String_val (vappsecret); 
	char* cappkey    = String_val (vappkey); 

	jstring jappid = (*env)->NewStringUTF(env, cappid);
	jstring jappsecret = (*env)->NewStringUTF(env, cappsecret);
	jstring jappkey = (*env)->NewStringUTF(env, cappkey);

	STATIC_MID(cls, init, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, jappid, jappsecret, jappkey);
	CAMLreturn(Val_unit);
}

value ok_authorize (value vfail, value vsuccess, value vforce) {
	CAMLparam2 (vfail,vsuccess);

	value *success, *fail;

	GET_ENV;
	GET_CLS;

	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	STATIC_MID(cls, authorize, "(IIZ)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail, vforce==Val_true ? JNI_TRUE: JNI_FALSE);
	CAMLreturn(Val_unit);
}

value ok_friends (value vfail, value vsuccess) {
	CAMLparam2 (vfail,vsuccess);

	value *success, *fail;

	GET_ENV;
	GET_CLS;

	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	STATIC_MID(cls, friends, "(II)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail);
	CAMLreturn(Val_unit);
}

value ok_users (value vfail, value vsuccess, value vids) {
	CAMLparam3 (vfail,vsuccess,vids);

	value *success, *fail;

	GET_ENV;
	GET_CLS;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	jstring jids;
	VAL_TO_JSTRING(vids, jids);
	STATIC_MID(cls, users, "(IILjava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, cls, mid, (jint)success, (jint)fail, jids);
	(*env)->DeleteLocalRef(env, jids);
	CAMLreturn(Val_unit); 
}
value ok_token (value unit) {
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

value ok_uid (value unit){
  CAMLparam0();
  CAMLlocal1(vuid);

  GET_ENV;
  GET_CLS;

  STATIC_MID(cls, uid, "()Ljava/lang/String;");
  jstring juid= (*env)->CallStaticObjectMethod(env, cls, mid);
  const char* cuid= (*env)->GetStringUTFChars(env, juid, JNI_FALSE);
  vuid= caml_copy_string(cuid);
  (*env)->ReleaseStringUTFChars(env, juid, cuid);

  CAMLreturn(vuid);
}

value ok_logout (value unit) {
  CAMLparam0();
	PRINT_DEBUG("ml OK: logout");
  GET_ENV;
  GET_CLS;

  STATIC_MID(cls, logout, "()V");
	(*env)->CallStaticObjectMethod(env, cls, mid);
	CAMLreturn(Val_unit);
}

void okandroid_auth_success(void *d) {
	value **data = (value**)d;
	PRINT_DEBUG("okandroid_auth_success");
	RUN_CALLBACK(data[0], Val_unit);
	PRINT_DEBUG("1");
	FREE_CALLBACK(data[0]);
	PRINT_DEBUG("2");
	FREE_CALLBACK(data[1]);
	PRINT_DEBUG("3");
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightOdnoklassniki_00024AuthSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail) {
	value **data = (value**)malloc(sizeof(value*)*2);
	data[0] = (value*)jsuccess;
	data[1] = (value*)jfail;
	RUN_ON_ML_THREAD(&okandroid_auth_success, (void*)data);
}

typedef struct {
	value *fail;
	value *success;
	char *reason;
} okandroid_fail_t;

void okandroid_fail(void *data) {
	okandroid_fail_t *fail = (okandroid_fail_t*)data;
	RUN_CALLBACK(fail->fail, caml_copy_string(fail->reason));
	FREE_CALLBACK(fail->fail);
	FREE_CALLBACK(fail->success);
	free(fail->reason);
	free(fail);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightOdnoklassniki_00024Fail_nativeRun(JNIEnv *env, jobject this, jint jfail, jstring jreason, jint jsuccess) {
	const char* creason = (*env)->GetStringUTFChars(env, jreason, JNI_FALSE);
	PRINT_DEBUG("creason '%s'", creason);
	okandroid_fail_t *fail = (okandroid_fail_t*)malloc(sizeof(okandroid_fail_t));

	fail->fail = (value*)jfail;
	fail->success = (value*)jsuccess;
	fail->reason = (char*)malloc(strlen(creason) + 1);
	strcpy(fail->reason, creason);

	(*env)->ReleaseStringUTFChars(env, jreason, creason);
	RUN_ON_ML_THREAD(&okandroid_fail, fail);
}

typedef struct {
	value *success;
	value *fail;
	jobjectArray friends;
} okandroid_friends_success_t;

void okandroid_friends_success(void *data) {
	okandroid_friends_success_t *friends_success = (okandroid_friends_success_t*)data;

	static value* create_friend = NULL;
	if (!create_friend) create_friend = caml_named_value("create_user");

	CAMLparam0();
	CAMLlocal2(retval, head);
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
		jclass cls = engine_find_class("ru/redspell/lightning/plugins/LightOdnoklassniki$Friend");

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

	RUN_CALLBACK(friends_success->success, retval);
	FREE_CALLBACK(friends_success->success);
	FREE_CALLBACK(friends_success->fail);

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, friends_success->friends);
	free(friends_success);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightOdnoklassniki_00024FriendsSuccess_nativeRun(JNIEnv *env, jobject this, jint jsuccess, jint jfail, jobjectArray jfriends) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightOdnoklassniki_00024FriendsSuccess_nativeRun");

	okandroid_friends_success_t *friends_success = (okandroid_friends_success_t*)malloc(sizeof(okandroid_friends_success_t));
	friends_success->success = (value*)jsuccess;
	friends_success->fail = (value*)jfail;
	friends_success->friends = (*env)->NewGlobalRef(env, jfriends);

	RUN_ON_ML_THREAD(&okandroid_friends_success, (void*)friends_success);
}
