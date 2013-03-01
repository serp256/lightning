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

void ml_fbConnect(value perms) {
    PRINT_DEBUG("ml_fbConnect");
    
    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "connect", "([Ljava/lang/String;)V");
    
    jstring c_perms[256];
    int perms_num = 0;

    if (perms != Val_int(0)) {
        value _perms = Field(perms, 0);
        value perm;

        while (Is_block(_perms)) {
            perm = Field(_perms, 0);
            jstring j_perm = (*env)->NewStringUTF(env, String_val(perm));
            c_perms[perms_num++] = j_perm;

            _perms = Field(_perms, 1);
        }
    }

    jclass stringCls = (*env)->FindClass(env, "Ljava/lang/String;");    
    jobjectArray j_perms = (*env)->NewObjectArray(env, perms_num, stringCls, NULL);
    (*env)->DeleteLocalRef(env, stringCls);
    
    int i;

    for (i = 0; i < perms_num; i++) {
        (*env)->SetObjectArrayElement(env, j_perms, i, c_perms[i]);
        (*env)->DeleteLocalRef(env, c_perms[i]);
    }

    (*env)->CallStaticVoidMethod(env, lightFacebookCls, mid, j_perms);
    (*env)->DeleteLocalRef(env, j_perms);
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

value ml_fbDisconnect(value connect) {
    PRINT_DEBUG("ml_fbDisconnect");

    GET_LIGHTFACEBOOK;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "disconnect", "()V");
    (*env)->CallStaticVoidMethod(env, lightFacebookCls, mid);
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

void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback) {
    value* _successCallback;
    value* _failCallback;
    PRINT_DEBUG("ml_fbAppRequest %d",gettid());

    REGISTER_CALLBACK(successCallback, _successCallback);
    REGISTER_CALLBACK(failCallback, _failCallback);

		PRINT_DEBUG("successCallback: %ld",_successCallback);

    GET_LIGHTFACEBOOK;

    jstring jtitle = (*env)->NewStringUTF(env, String_val(title));
    jstring jmessage = (*env)->NewStringUTF(env, String_val(message));
    jstring jrecipient = Is_block(recipient) ? (*env)->NewStringUTF(env, String_val(Field(recipient, 0))) : NULL;
		jstring jdata = Is_block(data) ? (*env)->NewStringUTF(env,String_val(Field(data,0))) : NULL;

    static jmethodID mid;
    if (!mid) mid = (*env)->GetStaticMethodID(env, lightFacebookCls, "apprequest", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;II)Z");

    jboolean allRight = (*env)->CallStaticBooleanMethod(env, lightFacebookCls, mid, jtitle, jmessage, jrecipient, jdata, (int)_successCallback, (int)_failCallback);

    (*env)->DeleteLocalRef(env, jtitle);
    (*env)->DeleteLocalRef(env, jmessage);
    if (jrecipient) (*env)->DeleteLocalRef(env, jrecipient);

    if (!allRight) caml_failwith("no active facebook session");
}

void ml_fbApprequest_byte(value * argv, int argn) {}

void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback) {
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
		PRINT_DEBUG("Java_ru_redspell_lightning_LightFacebook_00024CamlCallbackWithStringArrayParamRunnable_run %d",gettid());

    if (!callbackFid) {
        jclass selfCls = (*env)->GetObjectClass(env, this);
        callbackFid = (*env)->GetFieldID(env, selfCls, "callback", "I");
        paramFid = (*env)->GetFieldID(env, selfCls, "param", "[Ljava/lang/String;");
        (*env)->DeleteLocalRef(env, selfCls);
    }

    value* vcallback = (value*)(*env)->GetIntField(env, this, callbackFid);
		PRINT_DEBUG("successCallback: %ld",vcallback);

    if (vcallback) {
        jobjectArray jids = (*env)->GetObjectField(env, this, paramFid);
        int idsNum = (*env)->GetArrayLength(env, jids);
        value vids = Val_int(0);
        value vid = 0;
        const char* cid;
        jstring jid;
        value head = 0;
        int i;

				Begin_roots3(vid,head,vids);

        for (i = 0; i < idsNum; i++) {
					jid = (*env)->GetObjectArrayElement(env, jids, i);
					cid = (*env)->GetStringUTFChars(env, jid, JNI_FALSE);
					PRINT_DEBUG("array el: %s",cid);
					vid = caml_copy_string(cid);
					(*env)->ReleaseStringUTFChars(env, jid, cid);

					head = caml_alloc(2, 0);
					Store_field(head, 0, vid);
					Store_field(head, 1, vids);

					vids = head;
        };
        
        caml_callback(*vcallback, vids);
				End_roots();

				PRINT_DEBUG("END Java_ru_redspell_lightning_LightFacebook_00024CamlCallbackWithStringArrayParamRunnable_run");
    };
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightFacebook_00024CamlNamedValueWithStringAndValueParamsRunnable_run(JNIEnv *env, jobject this) {
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

    int param2 = (*env)->GetIntField(env, this, param2Fid);
    if (!param2) return;

    jstring jname = (*env)->GetObjectField(env, this, nameFid);
    const char* cname = (*env)->GetStringUTFChars(env, jname, JNI_FALSE);
    value* vcallback = caml_named_value(cname);

    if (vcallback) {
        jstring jparam1 = (*env)->GetObjectField(env, this, param1Fid);
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
		PRINT_DEBUG("Java_ru_redspell_lightning_LightFacebook_00024ReleaseCamlCallbacksRunnable_run");

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
		PRINT_DEBUG("END Java_ru_redspell_lightning_LightFacebook_00024ReleaseCamlCallbacksRunnable_run");
}
