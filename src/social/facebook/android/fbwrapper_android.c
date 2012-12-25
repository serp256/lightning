#include "fbwrapper_android.h"

#define GET_LIGHTFACEBOOK                                                       \
JNIEnv *env;                                                                    \
(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);                       \
                                                                                \
if (!lightFacebookCls) {                                                        \
    jclass cls = (*env)->FindClass(env, "ru/redspell/lightning/LightFacebook"); \
    lightFacebookCls = (*env)->NewGlobalRef(env, cls);                          \
    (*env)->DeleteLocalRef(env, cls);                                           \
}                                                                               \

#define FREE_CALLBACK(callback) if (callback) {                                     \
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

    jstring jappId = (*env)->NewStringUTF(env, String_val(appId));
    jmethodID mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "setAppId", "(Ljava/lang/String;)V");
    (*env)->CallStaticVoidMethod(env, lightFacebookCls, mid, jappId);
    (*env)->DeleteLocalRef(env, jappId);
}

void ml_fbConnect() {
    PRINT_DEBUG("ml_fbConnect");
    
    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "connect", "()V");

    (*env)->CallStaticVoidMethod(env, lightFacebookCls, mid);
}

value ml_fbLoggedIn() {
    PRINT_DEBUG("ml_fbLoggedIn");

    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "loggedIn", "()Z");

    value retval;

    if ((*env)->CallStaticBooleanMethod(env, lightFacebookCls, mid)) {
        retval = caml_alloc(1, 0);
        Store_field(retval, 0, Val_unit);
    } else {
        retval = Val_int(0);
    }

    return retval;
}

value ml_fbAccessToken(value connect) {
    PRINT_DEBUG("ml_fbAccessToken");

    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "accessToken", "()Ljava/lang/String;");

    jstring jaccessToken = (*env)->CallStaticObjectMethod(env, lightFacebookCls, mid);
    if (!jaccessToken) caml_failwith("no active facebook session");

    const char* caccessToken = (*env)->GetStringUTFChars(env, jaccessToken, JNI_FALSE);
    value vaccessToken = caml_copy_string(caccessToken);
    (*env)->ReleaseStringUTFChars(env, jaccessToken, caccessToken);

    return vaccessToken;
}

void ml_fbApprequest(value connect, value title, value message, value recipient, value successCallback, value failCallback) {
    value* _successCallback;
    value* _failCallback;

    REGISTER_CALLBACK(successCallback, _successCallback);
    REGISTER_CALLBACK(failCallback, _failCallback);

    GET_LIGHTFACEBOOK;

    jstring jtitle = (*env)->NewStringUTF(env, String_val(title));
    jstring jmessage = (*env)->NewStringUTF(env, String_val(message));
    jstring jrecipient = Is_block(recipient) ? (*env)->NewStringUTF(env, String_val(Field(recipient, 0))) : NULL;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "apprequest", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;II)Z");

    jboolean allRight = (*env)->CallStaticBooleanMethod(env, lightFacebookCls, mid, jtitle, jmessage, jrecipient, (int)_successCallback, (int)_failCallback);

    (*env)->DeleteLocalRef(env, jtitle);
    (*env)->DeleteLocalRef(env, jmessage);
    if (jrecipient) (*env)->DeleteLocalRef(env, jrecipient);

    if (!allRight) caml_failwith("no active facebook session");
}

void ml_fbApprequest_byte(value * argv, int argn) {}

void ml_fbGraphrequest(value connect, value path, value params, value successCallback, value failCallback) {
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
        bndlCls = (*env)->FindClass(env, "android/os/Bundle");
        bndlCid = (*env)->GetMethodID(env, bndlCls, "<init>", "()V");
        bndlPutStrMid = (*env)->GetMethodID(env, bndlCls, "putString", "(Ljava/lang/String;Ljava/lang/String;)V");
    }

    PRINT_DEBUG("checkpoint2");

    jstring jpath = (*env)->NewStringUTF(env, String_val(path));
    jobject jparams = (*env)->NewObject(env, bndlCls, bndlCid);
    jstring key;
    jstring val;

    PRINT_DEBUG("checkpoint3");

    if (params != Val_int(0)) {
        value _params = Field(params, 0);
        value param;

        while (Is_block(_params)) {
            param = Field(_params, 0);

            key = (*env)->NewStringUTF(env, String_val(Field(param, 0)));
            val = (*env)->NewStringUTF(env, String_val(Field(param, 1)));
            (*env)->CallVoidMethod(env, jparams, bndlPutStrMid, key, val);

            (*env)->DeleteLocalRef(env, key);
            (*env)->DeleteLocalRef(env, val);

            _params = Field(_params, 1);
        }
    }

    PRINT_DEBUG("checkpoint4");

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "graphrequest", "(Ljava/lang/String;Landroid/os/Bundle;II)Z");

    jboolean allRight = (*env)->CallStaticBooleanMethod(env, lightFacebookCls, mid, jpath, jparams, (int)_successCallback, (int)_failCallback);

    PRINT_DEBUG("checkpoint5");

    (*env)->DeleteLocalRef(env, jpath);
    (*env)->DeleteLocalRef(env, jparams);

    if (!allRight) caml_failwith("no active facebook session");
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlCallbackRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID callbackFid;

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    value* vcallback = (value*)(*env)->GetIntField(env, this, callbackFid);

    if (vcallback) {
        caml_callback(*vcallback, Val_unit);
    }
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlCallbackWithStringParamRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID callbackFid;
    static jfieldID paramFid;

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    value* vcallback = (value*)(*env)->GetIntField(env, this, callbackFid);

    if (vcallback) {
        jstring jparam = (*env)->GetObjectField(env, this, paramFid);
        const char* cparam = (*env)->GetStringUTFChars(env, jparam, JNI_FALSE);
        
        value vparam = caml_copy_string(cparam);
        caml_callback(*vcallback, vparam);

        (*env)->ReleaseStringUTFChars(env, jparam, cparam);
        (*env)->DeleteLocalRef(env, jparam);
    }
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlNamedValueRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID nameFid;

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    const char* cname = (*env)->GetStringUTFChars(env, jname, JNI_FALSE);
    value* vcallback = caml_named_value(cname);

    if (vcallback) {
        caml_callback(*vcallback, Val_unit);
    }

    (*env)->ReleaseStringUTFChars(env, jname, cname);
    (*env)->DeleteLocalRef(env, jname);    
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlNamedValueWithStringParamRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID nameFid;
    static jfieldID paramFid;

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    const char* cname = (*env)->GetStringUTFChars(env, jname, JNI_FALSE);
    value* vcallback = caml_named_value(cname);

    if (vcallback) {
        jstring jparam = (*env)->GetObjectField(env, this, paramFid);
        const char* cparam = (*env)->GetStringUTFChars(env, jparam, JNI_FALSE);

        value vparam = caml_copy_string(cparam);
        caml_callback(*vcallback, vparam);

        (*env)->ReleaseStringUTFChars(env, jparam, cparam);
        (*env)->DeleteLocalRef(env, jparam);
    }

    (*env)->ReleaseStringUTFChars(env, jname, cname);
    (*env)->DeleteLocalRef(env, jname);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlCallbackWithStringArrayParamRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID callbackFid;
    static jfieldID paramFid;

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "[Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    value* vcallback = (value*)(*env)->GetIntField(env, this, callbackFid);

    if (vcallback) {
        jobjectArray jids = (*env)->GetObjectField(env, this, paramFid);
        int idsNum = (*env)->GetArrayLength(env, jids);
        value vids = Val_int(0);
        value vid;
        const char* cid;
        jstring jid;
        value head;
        int i;

        for (i = 0; i < idsNum; i++) {
            jid = (*env)->GetObjectArrayElement(env, jids, i);
            cid = (*env)->GetStringUTFChars(env, jid, JNI_FALSE);
            vid = caml_copy_string(cid);
            (*env)->ReleaseStringUTFChars(env, jid, cid);

            head = caml_alloc(2, 0);
            Store_field(head, 0, vid);
            Store_field(head, 1, vids);

            vids = head;
        }
        
        caml_callback(*vcallback, vids);
    }
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlNamedValueWithStringAndValueParamsRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID nameFid;
    static jfieldID param1Fid;
    static jfieldID param2Fid;

    if (!nameFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        nameFid = (*env)->GetFieldID(env, selfCls, "name", "Ljava/lang/String;");
        param1Fid = (*env)->GetFieldID(env, selfCls, "param1", "Ljava/lang/String;");
        param2Fid = (*env)->GetFieldID(env, selfCls, "param2", "I");
        (*env)->DeleteLocalRef(env, selfCls);        
    }

    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    const char* cname = (*env)->GetStringUTFChars(env, jname, JNI_FALSE);
    value* vcallback = caml_named_value(cname);

    if (vcallback) {
        jstring jparam1 = (*env)->GetObjectField(env, this, param1Fid);
        int param2 = (*env)->GetIntField(env, this, param2Fid);
        const char* cparam1 = (*env)->GetStringUTFChars(env, jparam1, JNI_FALSE);

        value vparam1 = caml_copy_string(cparam1);
        caml_callback2(*vcallback, vparam1, *((value*)param2));

        (*env)->ReleaseStringUTFChars(env, jparam1, cparam1);
        (*env)->DeleteLocalRef(env, jparam1);
    }

    (*env)->ReleaseStringUTFChars(env, jname, cname);
    (*env)->DeleteLocalRef(env, jname);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024ReleaseCamlCallbacksRunnable_run(JNIEnv *env, jobject this) {
    static jfieldID successCbFid;
    static jfieldID failCbFid;

    if (!successCbFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        successCbFid = (*env)->GetFieldID(env, selfCls, "successCallback", "I");
        failCbFid = (*env)->GetFieldID(env, selfCls, "failCallback", "I");
        (*env)->DeleteLocalRef(env, selfCls);        
    }

    value* successCallback = (value*)(*env)->GetIntField(env, this, successCbFid);
    value* failCallback = (value*)(*env)->GetIntField(env, this, failCbFid);

    FREE_CALLBACK(successCallback);
    FREE_CALLBACK(failCallback);
}


/*#include "light_common.h"
#include "android/mlwrapper_android.h"

jclass getFbCls() {
    static jclass fbCls;

    if (!fbCls) {
        JNIEnv *env;
        (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

        jclass _fbCls = (*env)->FindClass(env, "ru/redspell/lightning/AndroidFB"); 
        fbCls = (*env)->NewGlobalRef(env, _fbCls);
        (*env)->DeleteLocalRef(env, _fbCls);
    }

    return fbCls;
}

void ml_fb_init(value app_id) {
    PRINT_DEBUG("+++++++++++++++++++++++++++++++++++++++++");
    PRINT_DEBUG("ml_fb_init");
  JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
    jclass fbCls = getFbCls();
    jmethodID init = (*env)->GetStaticMethodID(env, fbCls, "init", "(Ljava/lang/String;)V");
    jstring japp_id = (*env)->NewStringUTF(env, String_val(app_id));
  (*env)->CallStaticVoidMethod(env, fbCls, init, japp_id);
  (*env)->DeleteLocalRef(env, fbCls);
    (*env)->DeleteLocalRef(env, japp_id);
    PRINT_DEBUG("ml_fb_init FINISHED");
}


static value fb_auth_success = 0;
static value fb_auth_error = 0;

void ml_fb_authorize(value olen, value permissions, value cb, value ecb) {
    CAMLparam4(olen,permissions,cb,ecb);
    fb_auth_success = cb;
    caml_register_generational_global_root(&fb_auth_success);
    fb_auth_error = ecb;
    caml_register_generational_global_root(&fb_auth_error);
    int len = Int_val (olen);
    PRINT_DEBUG("ml_fb_authorize");
  JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
    PRINT_DEBUG("JNI GET");
    jclass fbCls = getFbCls();
    PRINT_DEBUG("CLASS FOUND ");
    jmethodID auth = (*env)->GetStaticMethodID(env, fbCls, "authorize", "([Ljava/lang/String;)V");
    PRINT_DEBUG("METHOD FOUND");
    
    jobjectArray jpermissions = (*env)->NewObjectArray(env,len,(*env)->FindClass(env,"java/lang/String"),(*env)->NewStringUTF(env,""));

    value perms = permissions;
    value v;
    int i = 0;
    while (perms != NILL) {
        v = Field(perms,0);
        (*env)->SetObjectArrayElement(env,jpermissions,i,(*env)->NewStringUTF(env,String_val(v)));
        i++;
        perms = Field(perms,1);
    }

  (*env)->CallStaticVoidMethod(env, fbCls, auth, jpermissions);
    PRINT_DEBUG("CALL METHOD");
  (*env)->DeleteLocalRef(env, fbCls);
  (*env)->DeleteLocalRef(env, jpermissions);
    PRINT_DEBUG("DELETE REF");

    CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_successAuthorize(JNIEnv *env, jobject this) {
    PRINT_DEBUG("AUTH SUCCESS CALLBACK");
    if (fb_auth_success) {
        caml_callback(fb_auth_success, Val_unit);
        caml_remove_generational_global_root(&fb_auth_success);
        fb_auth_success = 0;
    };
    if (fb_auth_error) {
        caml_remove_generational_global_root(&fb_auth_error);
        fb_auth_error = 0;
    };
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_errorAuthorize(JNIEnv *env, jobject this) {
    PRINT_DEBUG("AUTH ERROR CALLBACK");
    if (fb_auth_success) {
        caml_remove_generational_global_root(&fb_auth_success);
        fb_auth_success = 0;
    };
    if (fb_auth_error) {
        caml_callback(fb_auth_error, Val_unit);
        caml_remove_generational_global_root(&fb_auth_error);
        fb_auth_error = 0;
    };
}

static value fb_graph_callback = 0;
static value fb_graph_error = 0;

void ml_fb_graph_api(value cb, value ecb, value path, value oparams_len, value params) {
    CAMLparam5(path,oparams_len,params, cb, ecb);
    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
    jclass fbCls = getFbCls();
    PRINT_DEBUG("CLASS FOUND ");
    jmethodID graph_api = (*env)->GetStaticMethodID(env, fbCls, "graphAPI", "(Ljava/lang/String;[[Ljava/lang/String;)V");
    PRINT_DEBUG("METHOD FOUND");
    if (cb != NONE) {
        fb_graph_callback = Field(cb,0);
        caml_register_generational_global_root(&fb_graph_callback);
    };
    if (ecb != NONE) {
        fb_graph_error = Field(ecb,0);
        caml_register_generational_global_root(&fb_graph_error);
    };

    int len = Int_val(oparams_len);
    jobjectArray jparams = (*env)->NewObjectArray(env,len,(*env)->FindClass(env,"[Ljava/lang/String;"),(*env)->NewObjectArray(env,2,(*env)->FindClass(env, "java/lang/String"),(*env)->NewStringUTF(env,"pizda")));

    value prms = params;
    value v;
    int i = 0;
    while (prms != NILL) {
        v = Field(prms,0);
        jobjectArray jrow = (*env)->NewObjectArray(env,2,(*env)->FindClass(env, "java/lang/String"),(*env)->NewStringUTF(env,"pizda"));
        (*env)->SetObjectArrayElement(env,jrow,0,(*env)->NewStringUTF(env,String_val(Field(v,0))));
        (*env)->SetObjectArrayElement(env,jrow,1,(*env)->NewStringUTF(env,String_val(Field(v,1))));
        (*env)->SetObjectArrayElement(env,jparams,i,jrow);
        (*env)->DeleteLocalRef(env, jrow);
        i++;
        prms = Field(prms,1);
    }
    PRINT_DEBUG("GET PARAMS");
    (*env)->CallStaticVoidMethod(env, fbCls, graph_api, (*env)->NewStringUTF(env,String_val(path)),jparams );
    PRINT_DEBUG("FINISH METHOD");
    (*env)->DeleteLocalRef(env, fbCls);
    (*env)->DeleteLocalRef(env, jparams);

    CAMLreturn0;
}

value ml_fb_check_auth_token(value unit) {
    CAMLparam0();
    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
    jclass fbCls = getFbCls();
    jmethodID check = (*env)->GetStaticMethodID(env, fbCls, "check_auth_token", "()Z");
    value check_result = (Val_bool((*env)->CallStaticBooleanMethod(env, fbCls, check)));
    (*env)->DeleteLocalRef(env, fbCls);
    CAMLreturn(check_result);
}

value ml_fb_get_auth_token() {
    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
    
    jclass fbCls = getFbCls();
    static jmethodID getAuthTokenMid;
    if (!getAuthTokenMid) getAuthTokenMid = (*env)->GetStaticMethodID(env, fbCls, "getAccessToken", "()Ljava/lang/String;");
    jstring jauthToken = (*env)->CallStaticObjectMethod(env, fbCls, getAuthTokenMid);
    char* cauthToken = (*env)->GetStringUTFChars(env, jauthToken, JNI_FALSE);

    PRINT_DEBUG("cauthToken %s", cauthToken);

    value retval = caml_copy_string(cauthToken);

    (*env)->ReleaseStringUTFChars(env, jauthToken, cauthToken);
    (*env)->DeleteLocalRef(env, jauthToken);

    return retval;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_successGraphAPI(JNIEnv *env, jobject this, jstring response) {
    PRINT_DEBUG("SUCCESS CALLBACK");
    const char *l = (*env)->GetStringUTFChars(env, response, JNI_FALSE);
    jsize slen = (*env)->GetStringUTFLength(env,response);
    PRINT_DEBUG("SLEN %d", slen);
    value mresponse = caml_alloc_string(slen);
    memcpy(String_val(mresponse),l,slen);

    PRINT_DEBUG("GET STRING: %s",String_val(mresponse));
    if (fb_graph_callback) {
            PRINT_DEBUG("caml_callback start");
        caml_callback(fb_graph_callback, mresponse);
        caml_remove_generational_global_root(&fb_graph_callback);
        fb_graph_callback = 0;
    };
    PRINT_DEBUG("caml_callback finished");
    if (fb_graph_error) {
        caml_remove_generational_global_root(&fb_graph_error);
        fb_graph_error = 0;
    };
    (*env)->ReleaseStringUTFChars(env, response, l);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_errorGraphAPI(JNIEnv *env, jobject this, jstring error) {
    PRINT_DEBUG("ERROR CALLBACK");
    const char *l = (*env)->GetStringUTFChars(env, error, JNI_FALSE);
    value merror = caml_copy_string(l);

    PRINT_DEBUG("GET STRING: %s",String_val(merror));
    if (fb_graph_callback) {
        caml_remove_generational_global_root(&fb_graph_callback);
        fb_graph_callback = 0;
    };
    if (fb_graph_error) {
        caml_callback(fb_graph_error, merror);
        caml_remove_generational_global_root(&fb_graph_error);
        fb_graph_error = 0;
    };
    PRINT_DEBUG("caml_callback finished");
    (*env)->ReleaseStringUTFChars(env, error, l);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_AndroidFB_00024AppRequestDelegateRunnable_run(JNIEnv *env, jobject this) {
    PRINT_DEBUG("Java_ru_redspell_lightning_AndroidFB_00024AppRequestDelegateRunnable_run");

    static jclass runnableCls;
    static jfieldID delegateFid;
    static jfieldID recordFieldNumFid;
    static jfieldID paramFid;

    if (!runnableCls) {
        jclass _runnableCls = (*env)->GetObjectClass(env, this);
        runnableCls = (*env)->NewGlobalRef(env, _runnableCls);
        (*env)->DeleteLocalRef(env, _runnableCls);

        delegateFid = (*env)->GetFieldID(env, runnableCls, "_delegate", "I");
        recordFieldNumFid = (*env)->GetFieldID(env, runnableCls, "_recordFieldNum", "I");
        paramFid = (*env)->GetFieldID(env, runnableCls, "_param", "Ljava/lang/String;");
    }

    value* pdelegate = (value*)(*env)->GetIntField(env, this, delegateFid);
    value delegate = *pdelegate;

    if (delegate != Val_int(0)) {
        int recordFieldNum = (*env)->GetIntField(env, this, recordFieldNumFid);
        value cb = Field(Field(delegate, 0), recordFieldNum);

        if (cb != Val_int(0)) {
            jstring jparam = (*env)->GetObjectField(env, this, paramFid);
            value param = Val_unit;

            if (jparam) {
                const char* cparam = (*env)->GetStringUTFChars(env, jparam, JNI_FALSE);
                param = caml_copy_string(cparam);
                (*env)->ReleaseStringUTFChars(env, jparam, cparam);
                (*env)->DeleteLocalRef(env, jparam);
            }

            caml_callback(Field(cb, 0), param);
        }
    }

    caml_remove_generational_global_root(pdelegate);
    free(pdelegate);
}

void ml_facebook_open_apprequest_dialog(value mes, value recipients, value filter, value title, value delegate) {
    PRINT_DEBUG("ml_facebook_open_apprequest_dialog call");

    CAMLparam4(mes, recipients, filter, title); 

    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

    jclass fbCls = getFbCls();
    static jmethodID showAppReqDlgMid;

    if (!showAppReqDlgMid) {
        showAppReqDlgMid = (*env)->GetStaticMethodID(env, fbCls, "showAppRequestDialog", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V");
    }

    char* cmes = String_val(mes);
    char* crecipients = String_val(recipients);
    char* cfilter = String_val(filter);
    char* ctitle = String_val(title);

    jstring jmes = (*env)->NewStringUTF(env, cmes);
    jstring jrecipients = (*env)->NewStringUTF(env, crecipients);
    jstring jfilter = (*env)->NewStringUTF(env, cfilter);
    jstring jtitle = (*env)->NewStringUTF(env, ctitle);

    value* pdelegate = malloc(sizeof(value));
    *pdelegate = delegate;
    caml_register_generational_global_root(pdelegate);

    (*env)->CallStaticVoidMethod(env, fbCls, showAppReqDlgMid, jmes, jrecipients, jfilter, jtitle, (jint)pdelegate);

    (*env)->DeleteLocalRef(env, jmes);
    (*env)->DeleteLocalRef(env, jrecipients);
    (*env)->DeleteLocalRef(env, jfilter);
    (*env)->DeleteLocalRef(env, jtitle);

    CAMLreturn0;
}*/