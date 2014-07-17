#include "engine.h"
#include "lightning_android.h"
#include "mlwrapper_android.h"

#include <pthread.h>

jclass lightning_cls;

void lightning_init() {
    PRINT_DEBUG("1");

    lightning_cls = engine_find_class("ru/redspell/lightning/v2/Lightning");
    PRINT_DEBUG("2 %d", lightning_cls);
    jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "init", "()V");
    PRINT_DEBUG("3");
    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid);
    PRINT_DEBUG("4");
}

char *lightning_get_locale() {
	static char *retval = NULL;

    if (!retval) {
        jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "locale", "()Ljava/lang/String;");
        jstring jlocale = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
        const char* clocale = (*ML_ENV)->GetStringUTFChars(ML_ENV, jlocale, NULL);
        retval = malloc(strlen(clocale) + 1);
        strcpy(retval, clocale);

        (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jlocale, clocale);
        (*ML_ENV)->DeleteLocalRef(ML_ENV, jlocale);
    }

    return retval;
}

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *env, jclass this) {
    return JAVA_ACTIVITY;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Lightning_disableTouches(JNIEnv *env, jclass this) {
    engine.touches_disabled = 1;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Lightning_enableTouches(JNIEnv *env, jclass this) {
    engine.touches_disabled = 0;
}

void lightning_set_referer(const char *ctype, jstring jnid) {
    CAMLparam0();
    CAMLlocal2(vtype,vnid);

    vtype = caml_copy_string(ctype);
    JSTRING_TO_VAL(jnid, vnid);
    set_referrer_ml(vtype, vnid);

    CAMLreturn0;    
}

void lightning_convert_intent(void *data) {
    jobject intent = (jobject)data;
    static jclass intent_cls = NULL;
    static jclass bundle_cls = NULL;
    static jmethodID getextras_mid;
    static jmethodID getstring_mid;

    if (!intent_cls) {
        intent_cls = engine_find_class("android/content/Intent");
        bundle_cls = engine_find_class("android/os/Bundle");
        getextras_mid = (*ML_ENV)->GetMethodID(ML_ENV, intent_cls, "getExtras", "()Landroid/os/Bundle;");
        getstring_mid = (*ML_ENV)->GetMethodID(ML_ENV, bundle_cls, "getString", "(Ljava/lang/String;)Ljava/lang/String;");
    }

    jobject extras = (*ML_ENV)->CallObjectMethod(ML_ENV, intent, getextras_mid);
    if (extras) {
        jstring key = (*ML_ENV)->NewStringUTF(ML_ENV, "localNotification");
        jstring nid = (*ML_ENV)->CallObjectMethod(ML_ENV, extras, getstring_mid, key);

        if (nid) {
            lightning_set_referer("local", nid);
            (*ML_ENV)->DeleteLocalRef(ML_ENV, key);
            (*ML_ENV)->DeleteLocalRef(ML_ENV, nid);
        } else {
            (*ML_ENV)->DeleteLocalRef(ML_ENV, key);
            key = (*ML_ENV)->NewStringUTF(ML_ENV, "remoteNotification");
            nid = (*ML_ENV)->CallObjectMethod(ML_ENV, extras, getstring_mid, key);

            if (nid) {
                lightning_set_referer("remote", nid);
                (*ML_ENV)->DeleteLocalRef(ML_ENV, nid);
            }

            (*ML_ENV)->DeleteLocalRef(ML_ENV, key);
        }

        (*ML_ENV)->DeleteLocalRef(ML_ENV, extras);
    }
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Lightning_convertIntent(JNIEnv *env, jclass this, jobject intent) {
    RUN_ON_ML_THREAD(&lightning_convert_intent, (void*)(*env)->NewGlobalRef(env, intent));
}
