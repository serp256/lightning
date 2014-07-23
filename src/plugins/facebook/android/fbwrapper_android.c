#include "fbwrapper_android.h"

#define GET_LIGHTFACEBOOK if (!lightFacebookCls) lightFacebookCls = engine_find_class("com/facebook/LightFacebook");

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

void ml_fbInit(value appId) {
    PRINT_DEBUG("ml_fbInit");
    GET_LIGHTFACEBOOK;
    jstring jappId = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(appId));
    jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "init", "(Ljava/lang/String;)V");
    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightFacebookCls, mid, jappId);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, jappId);
}

void ml_fbConnect(value perms) {
    PRINT_DEBUG("ml_fbConnect");
    
    GET_LIGHTFACEBOOK;

    PRINT_DEBUG("chckpnt1");

    static jmethodID mid;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "connect", "([Ljava/lang/String;)V");

    PRINT_DEBUG("chckpnt2");
    
    jstring c_perms[256];
    int perms_num = 0;

    if (perms != Val_int(0)) {
        PRINT_DEBUG("chckpnt2.1");

        value _perms = Field(perms, 0);
        value perm;

        PRINT_DEBUG("chckpnt2.2");

        while (Is_block(_perms)) {
            perm = Field(_perms, 0);
            PRINT_DEBUG("perms %s", String_val(perm));
            jstring j_perm = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(perm));
            c_perms[perms_num++] = j_perm;

            _perms = Field(_perms, 1);
        }
    }

    PRINT_DEBUG("chckpnt3");

    jclass stringCls = (*ML_ENV)->FindClass(ML_ENV, "java/lang/String");
    jobjectArray j_perms = (*ML_ENV)->NewObjectArray(ML_ENV, perms_num, stringCls, NULL);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, stringCls);

    PRINT_DEBUG("chckpnt4");
    
    int i;

    for (i = 0; i < perms_num; i++) {
        PRINT_DEBUG("4.1");

        (*ML_ENV)->SetObjectArrayElement(ML_ENV, j_perms, i, c_perms[i]);
        PRINT_DEBUG("4.2");
        (*ML_ENV)->DeleteLocalRef(ML_ENV, c_perms[i]);
        PRINT_DEBUG("4.3");
    }

    PRINT_DEBUG("chckpnt5");

    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightFacebookCls, mid, j_perms);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, j_perms);

    PRINT_DEBUG("chckpnt6");
}

value ml_fbLoggedIn() {
    PRINT_DEBUG("ml_fbLoggedIn");

    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "loggedIn", "()Z");

    value retval;

    if ((*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightFacebookCls, mid)) {
        retval = caml_alloc(1, 0);
        Store_field(retval, 0, Val_unit);
    } else {
        retval = Val_int(0);
    }

    return retval;
}

value ml_fbDisconnect(value connect) {
    PRINT_DEBUG("ml_fbDisconnect");

    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "disconnect", "()V");
    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightFacebookCls, mid);

    return Val_unit;
}

value ml_fbAccessToken(value connect) {
    PRINT_DEBUG("ml_fbAccessToken");

    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "accessToken", "()Ljava/lang/String;");

    jstring jaccessToken = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightFacebookCls, mid);
    if (!jaccessToken) caml_failwith("no active facebook session");

    const char* caccessToken = (*ML_ENV)->GetStringUTFChars(ML_ENV, jaccessToken, JNI_FALSE);
    value vaccessToken = caml_copy_string(caccessToken);
    (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jaccessToken, caccessToken);

    return vaccessToken;
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

void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback, value http_method) {
    PRINT_DEBUG("ml_fbGraphrequest");

    value* _successCallback;
    value* _failCallback;

    REGISTER_CALLBACK(successCallback, _successCallback);
    REGISTER_CALLBACK(failCallback, _failCallback);

    GET_LIGHTFACEBOOK;

    static jclass bndlCls;
    static jmethodID bndlCid;
    static jmethodID bndlPutStrMid;

    PRINT_DEBUG("checkpoint1");

    if (!bndlCls) {
        jclass cls = (*ML_ENV)->FindClass(ML_ENV, "android/os/Bundle");
        bndlCls = (*ML_ENV)->NewGlobalRef(ML_ENV, cls);
        (*ML_ENV)->DeleteLocalRef(ML_ENV, cls);

        bndlCid = (*ML_ENV)->GetMethodID(ML_ENV, bndlCls, "<init>", "()V");
        bndlPutStrMid = (*ML_ENV)->GetMethodID(ML_ENV, bndlCls, "putString", "(Ljava/lang/String;Ljava/lang/String;)V");
    }

    PRINT_DEBUG("checkpoint2");

    jstring jpath = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(path));
    jobject jparams = (*ML_ENV)->NewObject(ML_ENV, bndlCls, bndlCid);
    jstring key;
    jstring val;

    PRINT_DEBUG("checkpoint3");

    if (params != Val_int(0)) {
        value _params = Field(params, 0);
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

    static jmethodID mid;
    if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightFacebookCls, "graphrequest", "(Ljava/lang/String;Landroid/os/Bundle;III)Z");

    static value get_variant = 0;
    if (!get_variant) get_variant = caml_hash_variant("get");

    jboolean allRight = (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightFacebookCls, mid, jpath, jparams, (int)_successCallback, (int)_failCallback, http_method == get_variant ? 0 : 1);

    PRINT_DEBUG("checkpoint5");

    (*ML_ENV)->DeleteLocalRef(ML_ENV, jpath);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, jparams);

    if (!allRight) caml_failwith("no active facebook session");
}

void fbandroid_callback(void *data) {
    caml_callback(*((value*)data), Val_unit);   
}

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024CamlCallbackRunnable_run(JNIEnv *env, jobject this) {
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
    fbandroid_callback_with_str_t *data = (fbandroid_callback_with_str_t*)d;

    value vparam;
    JSTRING_TO_VAL(data->str, vparam);
    caml_callback(*data->callbck, vparam);

    (*ML_ENV)->DeleteGlobalRef(ML_ENV, data->str);
    free(data);
}

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024CamlCallbackWithStringParamRunnable_run(JNIEnv *env, jobject this) {
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

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024CamlNamedValueRunnable_run(JNIEnv *env, jobject this) {
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

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024CamlNamedValueWithStringParamRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID nameFid;
    static jfieldID paramFid;

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    jstring jparam = (*env)->GetObjectField(env, this, paramFid);
    jstring *data = (jstring*)malloc(sizeof(jstring) * 2);
    data[0] = (*env)->NewGlobalRef(env, jname);
    data[1] = (*env)->NewGlobalRef(env, jparam);
    RUN_ON_ML_THREAD(&fbandroid_named_with_str, (void*)data);

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

JNIEXPORT void JNICALL Java_com_facebook_LightFacebook_00024ReleaseCamlCallbacksRunnable_run(JNIEnv *env, jobject this) {
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
