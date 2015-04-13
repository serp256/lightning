#include "fbwrapper_android.h"
#include <caml/callback.h>

#define GET_LIGHTFACEBOOK if (!lightFacebookCls) lightFacebookCls = engine_find_class("com/facebook/LightFacebook");

static jclass cls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(cls,ru/redspell/lightning/plugins/LightFacebook);

#define FB_ANDROID_FREE_CALLBACK(callback) if (callback) {                                     \
    caml_remove_generational_global_root(callback);                                 \
    free(callback);                                                                 \
}                                                                                   \

#define REGISTER_CALLBACK(callback, pointer) if (callback != Val_int(0)) {  \
    pointer = (value*)malloc(sizeof(value));                                \
    *pointer = Field(callback, 0);                                          \
    caml_register_generational_global_root(pointer);                        \
} else {                                                                    \
    pointer = NULL;                                                         \
}                                                                           \

static jclass lightFacebookCls = NULL;

value ml_fbInit(value vappId) {
	CAMLparam1 (vappId);

	PRINT_DEBUG("ml_fbInit");
	GET_ENV;
	GET_CLS;


	STATIC_MID(cls, init, "(Ljava/lang/String;)V");
	jstring jappId = (*env)->NewStringUTF(env, String_val(vappId));
	(*env)->CallStaticVoidMethod(env, cls, mid, jappId);

	CAMLreturn(Val_unit);
}

value ml_fbConnect(value vperms) {
	CAMLparam1(vperms);
	CAMLlocal2(v_perms, vperm);
	PRINT_DEBUG("ml_fbConnect");

	GET_ENV;
	GET_CLS;


    PRINT_DEBUG("chckpnt1");

    jstring jperms[256];
    int perms_num = 0;

    if (vperms != Val_int(0)) {
        PRINT_DEBUG("chckpnt2.1");

        value v_perms = Field(vperms, 0);
        value vperm;

        PRINT_DEBUG("chckpnt2.2");

        while (Is_block(v_perms)) {
            vperm = Field(v_perms, 0);
            PRINT_DEBUG("perms %s", String_val(vperm));

						jstring jperm;
						VAL_TO_JSTRING(vperm, jperm);
            jperms[perms_num++] = jperm;

            v_perms = Field(v_perms, 1);
        }
    }

    PRINT_DEBUG("chckpnt3");

    jclass stringCls = (*env)->FindClass(env, "java/lang/String");
    jobjectArray j_perms_array = (*env)->NewObjectArray(env, perms_num, stringCls, NULL);
    (*env)->DeleteLocalRef(env, stringCls);

    PRINT_DEBUG("chckpnt4");
    
    int i;

    for (i = 0; i < perms_num; i++) {
        PRINT_DEBUG("4.1");
        PRINT_DEBUG("%d %d", i, perms_num);

        (*env)->SetObjectArrayElement(env, j_perms_array, i, jperms[i]);
        PRINT_DEBUG("4.2");
        (*env)->DeleteLocalRef(env, jperms[i]);
        PRINT_DEBUG("4.3");
    }

    PRINT_DEBUG("chckpnt5");

		STATIC_MID(cls, connect, "([Ljava/lang/String;)V");
    PRINT_DEBUG("chckpnt6");
		(*env)->CallStaticVoidMethod(env, cls, mid, j_perms_array);
    (*env)->DeleteLocalRef(env, j_perms_array);
    PRINT_DEBUG("chckpnt7");

		CAMLreturn(Val_unit);
}

value ml_fbLoggedIn() {
	CAMLparam0();
    PRINT_DEBUG("ml_fbLoggedIn");

		GET_ENV;
		GET_CLS;

		STATIC_MID(cls, loggedIn, "()Z");

		if ((*env)->CallStaticBooleanMethod(env,cls,mid)) {
			return (Val_bool(1));
		}
		else {
			return (Val_bool(0));
		}
		CAMLreturn (Val_unit);
}

value ml_fbDisconnect(value unit) {
	PRINT_DEBUG("ml_fbDisconnect");

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, disconnect, "()V");
	(*env)->CallStaticVoidMethod(env, cls, mid);
}

value ml_fbAccessToken(value unit) {
	CAMLparam0();
	CAMLlocal1(vtoken);

	PRINT_DEBUG("ml_fbAccessToken");
	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, accessToken, "()Ljava/lang/String;");

	PRINT_DEBUG("call");
	jstring jtoken = (*env)->CallStaticObjectMethod(env, cls, mid);
	PRINT_DEBUG("after call");
	const char* ctoken = (*env)->GetStringUTFChars(env, jtoken, JNI_FALSE);
	vtoken = caml_copy_string(ctoken);
	(*env)->ReleaseStringUTFChars(env, jtoken, ctoken);

	CAMLreturn(vtoken);
}

value ml_fbGraphrequest(value vpath, value vparams, value vsuccess, value vfail, value vhttp_method) {
	CAMLparam5(vpath, vparams, vsuccess, vfail, vhttp_method);
    PRINT_DEBUG("ml_fbGraphrequest");

    value* success;
    value* fail;

    REGISTER_CALLBACK(vsuccess, success);
    REGISTER_CALLBACK(vfail, fail);

		GET_ENV;
    GET_CLS;

    static jclass bndlCls;
    static jmethodID bndlCid;
    static jmethodID bndlPutStrMid;

    PRINT_DEBUG("checkpoint1");

    if (!bndlCls) {
        jclass bcls = (*env)->FindClass(env, "android/os/Bundle");
        bndlCls = (*env)->NewGlobalRef(env, bcls);
        (*env)->DeleteLocalRef(env, bcls);

        bndlCid = (*env)->GetMethodID(env, bndlCls, "<init>", "()V");
        bndlPutStrMid = (*env)->GetMethodID(env, bndlCls, "putString", "(Ljava/lang/String;Ljava/lang/String;)V");
    }

    PRINT_DEBUG("checkpoint2");

    jstring jpath = (*env)->NewStringUTF(env, String_val(vpath));
    jobject jparams = (*env)->NewObject(env, bndlCls, bndlCid);
    jstring key;
    jstring val;

    PRINT_DEBUG("checkpoint3");

		CAMLlocal2(_params,param);
    if (vparams != Val_int(0)) {
				value _params = Field(vparams, 0);
				value param;

        while (Is_block(_params)) {
            param = Field(_params, 0);

            key = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(Field(param, 0)));
            val = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(Field(param, 1)));
            (*ML_ENV)->CallVoidMethod(ML_ENV, jparams, bndlPutStrMid, key, val);

            (*ML_ENV)->DeleteLocalRef(ML_ENV, key);
            (*ML_ENV)->DeleteLocalRef(ML_ENV, val);

            _params = Field(_params, 1);
        }
    }

    PRINT_DEBUG("checkpoint4");

		STATIC_MID(cls, graphrequest, "(Ljava/lang/String;Landroid/os/Bundle;III)V");

    static value get_variant = 0;
    if (!get_variant) get_variant = caml_hash_variant("get");

    (*env)->CallStaticVoidMethod(env, cls, mid, jpath, jparams, (int)success, (int)fail, vhttp_method == get_variant ? 0 : 1);

    PRINT_DEBUG("checkpoint5");

    (*ML_ENV)->DeleteLocalRef(ML_ENV, jpath);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, jparams);

		CAMLreturn(Val_unit);
}
void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback) {
    value* _successCallback;
    value* _failCallback;

    REGISTER_CALLBACK(successCallback, _successCallback);
    REGISTER_CALLBACK(failCallback, _failCallback);

    GET_LIGHTFACEBOOK;

    jstring jtitle = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(title));
    jstring jmessage = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(message));
    jstring jrecipient = Is_block(recipient) ? (*ML_ENV)->NewStringUTF(ML_ENV, String_val(Field(recipient, 0))) : NULL;
		jstring jdata = Is_block(data) ? (*ML_ENV)->NewStringUTF(ML_ENV,String_val(Field(data,0))) : NULL;

    static jmethodID mid;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "apprequest", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;II)Z");

    jboolean allRight = (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightFacebookCls, mid, jtitle, jmessage, jrecipient, jdata, (int)_successCallback, (int)_failCallback);

    (*ML_ENV)->DeleteLocalRef(ML_ENV, jtitle);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, jmessage);
    if (jrecipient) (*ML_ENV)->DeleteLocalRef(ML_ENV, jrecipient);

    if (!allRight) caml_failwith("no active facebook session");
}

void ml_fbApprequest_byte(value * argv, int argn) {}

void fbandroid_callback(void *data) {
    caml_callback(*((value*)data), Val_unit);   
}


JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlCallbackInt_run(JNIEnv *env, jobject this) {
    PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlCallbackInt_run");
    static jfieldID callbackFid;

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    RUN_ON_ML_THREAD(&fbandroid_callback, (void*)(*env)->GetIntField(env, this, callbackFid));
}

typedef struct {
    value *callbck;
    jstring str;
} fbandroid_callback_with_str_t;

void fbandroid_callback_with_str(void *d) {
    PRINT_DEBUG("fbandroid_callback_with_str");

    fbandroid_callback_with_str_t *data = (fbandroid_callback_with_str_t*)d;

    value vparam;
    JSTRING_TO_VAL(data->str, vparam);
    caml_callback(*data->callbck, vparam);

    (*ML_ENV)->DeleteGlobalRef(ML_ENV, data->str);
    free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlParamCallbackInt_run(JNIEnv *env, jobject this) {
    PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlParamCallbackInt_run");

    static jfieldID callbackFid;
    static jfieldID paramFid;

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    jstring jparam = (*env)->GetObjectField(env, this, paramFid);
    fbandroid_callback_with_str_t *data = (fbandroid_callback_with_str_t*)malloc(sizeof(fbandroid_callback_with_str_t));
    data->callbck = (value*)(*env)->GetIntField(env, this, callbackFid);
    data->str = (*env)->NewGlobalRef(env, jparam);

    RUN_ON_ML_THREAD(&fbandroid_callback_with_str, (void*)data);

    (*env)->DeleteLocalRef(env, jparam);
}

void fbandroid_named(void *data) {
    jstring jname = (jstring)data;

    const char* cname = (*ML_ENV)->GetStringUTFChars(ML_ENV, jname, JNI_FALSE);
    caml_callback(*caml_named_value(cname), Val_unit);

    (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jname, cname);
    (*ML_ENV)->DeleteGlobalRef(ML_ENV, jname);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlCallback_run(JNIEnv *env, jobject this) {
    PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlCallback_run");
    static jfieldID nameFid;

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    RUN_ON_ML_THREAD(&fbandroid_named, (void*)(*env)->NewGlobalRef(env, jname));
    (*env)->DeleteLocalRef(env, jname);    
}

void fbandroid_named_with_str(void *d) {
    jstring *data = (jstring*)d;
    jstring jname = data[0];
    jstring jparam = data[1];

    const char* cname = (*ML_ENV)->GetStringUTFChars(ML_ENV, jname, JNI_FALSE);
    const char* cparam = (*ML_ENV)->GetStringUTFChars(ML_ENV, jparam, JNI_FALSE);
    caml_callback(*caml_named_value(cname), caml_copy_string(cparam));

    (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jparam, cparam);
    (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jname, cname);
    (*ML_ENV)->DeleteGlobalRef(ML_ENV, jparam);
    (*ML_ENV)->DeleteGlobalRef(ML_ENV, jname);
    free(data);    
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlParamCallback_run(JNIEnv *env, jobject this) {
    PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightFacebook_00024CamlParamCallback_run");
    static jfieldID nameFid;
    static jfieldID paramFid;

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

		PRINT_DEBUG("chp1");
    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    jstring jparam = (*env)->GetObjectField(env, this, paramFid);
		PRINT_DEBUG("chp2");
    jstring *data = (jstring*)malloc(sizeof(jstring) * 2);
    data[0] = (*env)->NewGlobalRef(env, jname);
    data[1] = (*env)->NewGlobalRef(env, jparam);
		PRINT_DEBUG("chp3");
    RUN_ON_ML_THREAD(&fbandroid_named_with_str, (void*)data);

		PRINT_DEBUG("chp4");
    (*env)->DeleteLocalRef(env, jparam);
    (*env)->DeleteLocalRef(ML_ENV, jname);
}
typedef struct {
    value *callbck;
    jobjectArray arr;
} fbandroid_named_t;

void fbandroid_callback_with_str_ar(void *d) {
    fbandroid_named_t *data = (fbandroid_named_t*)d;

    jobjectArray jids = data->arr;
    int idsNum = (*ML_ENV)->GetArrayLength(ML_ENV, jids);
    value vids = Val_int(0);
    value vid = 0;
    const char* cid;
    jstring jid;
    value head = 0;
    int i;

    Begin_roots3(vid,head,vids);

    for (i = 0; i < idsNum; i++) {
        jid = (*ML_ENV)->GetObjectArrayElement(ML_ENV, jids, i);
        cid = (*ML_ENV)->GetStringUTFChars(ML_ENV, jid, JNI_FALSE);
        PRINT_DEBUG("array el: %s",cid);
        vid = caml_copy_string(cid);
        (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jid, cid);

        head = caml_alloc(2, 0);
        Store_field(head, 0, vid);
        Store_field(head, 1, vids);

        vids = head;
    };
    
    caml_callback(*data->callbck, vids);
    End_roots();

    (*ML_ENV)->DeleteGlobalRef(ML_ENV, jids);
    free(data);
}

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024CamlCallbackWithStringArrayParamRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID callbackFid;
    static jfieldID paramFid;
		PRINT_DEBUG("Java_ru_redspell_lightning_LightFacebook_00024CamlCallbackWithStringArrayParamRunnable_run %d",gettid());

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "[Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    fbandroid_named_t *data = (fbandroid_named_t*)malloc(sizeof(fbandroid_named_t));
    jobjectArray jids = (*env)->GetObjectField(env, this, paramFid);
    data->callbck = (value*)(*env)->GetIntField(env, this, callbackFid);
    data->arr = (*env)->NewGlobalRef(env, jids);

    RUN_ON_ML_THREAD(&fbandroid_callback_with_str_ar, (void*)data);

    (*env)->DeleteLocalRef(env, jids);
}

typedef struct {
    jstring name;
    jstring param1;
    value *param2;
} fbandroid_named_with_str_n_val_t;

void fbandroid_named_with_str_n_val(void *d) {
    fbandroid_named_with_str_n_val_t *data = (fbandroid_named_with_str_n_val_t*)d;

    const char* cname = (*ML_ENV)->GetStringUTFChars(ML_ENV, data->name, JNI_FALSE);
    value param1;
    JSTRING_TO_VAL(data->param1, param1);

    caml_callback2(*caml_named_value(cname), param1, *data->param2);

    (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, data->name, cname);
    (*ML_ENV)->DeleteGlobalRef(ML_ENV, data->name);
    (*ML_ENV)->DeleteGlobalRef(ML_ENV, data->param1);
    free(data);
}

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024CamlNamedValueWithStringAndValueParamsRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID nameFid;
    static jfieldID param1Fid;
    static jfieldID param2Fid;

	PRINT_DEBUG("Java_ru_redspell_lightning_LightFacebook_00024CamlNamedValueWithStringAndValueParamsRunnable_run");

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        param1Fid = (*env)->GetFieldID(env, selfCls, "param1", "Ljava/lang/String;");
        param2Fid = (*env)->GetFieldID(env, selfCls, "param2", "I");
        (*env)->DeleteLocalRef(env, selfCls);        
    }

    fbandroid_named_with_str_n_val_t *data = (fbandroid_named_with_str_n_val_t*)malloc(sizeof(fbandroid_named_with_str_n_val_t));
    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    jstring jparam1 = (*env)->GetObjectField(env, this, param1Fid);

    data->name = (*env)->NewGlobalRef(env, jname);
    data->param1 = (*env)->NewGlobalRef(env, jparam1);
    data->param2 = (value*)(*env)->GetIntField(env, this, param2Fid);

    RUN_ON_ML_THREAD(&fbandroid_named_with_str_n_val, (void*)data);

    (*env)->DeleteLocalRef(env, jname);
    (*env)->DeleteLocalRef(env, jparam1);
}

void fbandroid_release_callbacks(void *d) {
    value **data = (value**)d;
    FB_ANDROID_FREE_CALLBACK(data[0]);
    FB_ANDROID_FREE_CALLBACK(data[1]);
    free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_plugins_LightFacebook_00024ReleaseCamlCallbacks_run(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_plugins_LightFacebook_00024ReleaseCamlCallbacks_run");
    static jfieldID successCbFid;
    static jfieldID failCbFid;

    if (!successCbFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        successCbFid = (*env)->GetFieldID(env, selfCls, "successCallback", "I");
        failCbFid = (*env)->GetFieldID(env, selfCls, "failCallback", "I");
        (*env)->DeleteLocalRef(env, selfCls);        
    }

    value **data = (value**)malloc(sizeof(value*));

    data[0] = (value*)(*env)->GetIntField(env, this, successCbFid);
    data[1] = (value*)(*env)->GetIntField(env, this, failCbFid);

    RUN_ON_ML_THREAD(&fbandroid_release_callbacks, (void*)data);
}

value ml_fb_share_pic_using_native_app(value v_fname, value v_text) {
    GET_LIGHTFACEBOOK;

    jstring j_fname, j_text; 
    VAL_TO_JSTRING(v_fname, j_fname);
    VAL_TO_JSTRING(v_text, j_text);

    static jmethodID mid = 0;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "sharePicUsingNativeApp", "(Ljava/lang/String;Ljava/lang/String;)Z");

    jboolean retval = (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightFacebookCls, mid, j_fname, j_text);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, j_fname);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, j_text);

    return (retval ? Val_true : Val_false);
}

value ml_fb_share_pic(value v_success, value v_fail, value v_fname, value v_text) {
    CAMLparam4(v_fname, v_text, v_success, v_fail);

    GET_LIGHTFACEBOOK;

    value* _success;
    value* _fail;

    REGISTER_CALLBACK(v_success, _success);
    REGISTER_CALLBACK(v_fail, _fail);

    jstring j_fname, j_text;
    VAL_TO_JSTRING(v_fname, j_fname);
    VAL_TO_JSTRING(v_text, j_text);    

    static jmethodID mid = 0;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "sharePic", "(Ljava/lang/String;Ljava/lang/String;II)Z");

    jboolean retval = (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightFacebookCls, mid, j_fname, j_text, (jint)_success, (jint)_fail);

    (*ML_ENV)->DeleteLocalRef(ML_ENV, j_fname);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, j_text);

    if (!retval) caml_failwith("no active facebook session");

    CAMLreturn(Val_unit);
}

value ml_fb_share(value v_text, value v_link, value v_picUrl, value v_success, value v_fail, value unit) {
    CAMLparam5(v_text, v_link, v_picUrl, v_success, v_fail);
    GET_LIGHTFACEBOOK;

    value* success;
    value* fail;

    jstring j_link, j_text, j_picUrl;
    REGISTER_CALLBACK(v_success, success);
    REGISTER_CALLBACK(v_fail, fail);
    OPTVAL_TO_JSTRING(v_link, j_link);
    OPTVAL_TO_JSTRING(v_text, j_text);    
    OPTVAL_TO_JSTRING(v_picUrl, j_picUrl);

    static jmethodID mid = 0;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "share", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;II)V");
    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightFacebookCls, mid, j_text, j_link, j_picUrl, (jint)success, (jint)fail);

    if (j_text) (*ML_ENV)->DeleteLocalRef(ML_ENV, j_text);
    if (j_link) (*ML_ENV)->DeleteLocalRef(ML_ENV, j_link);
    if (j_picUrl) (*ML_ENV)->DeleteLocalRef(ML_ENV, j_picUrl);

    CAMLreturn(Val_unit);
}

value ml_fb_share_byte(value* argv, int argn) {
    return ml_fb_share(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}
